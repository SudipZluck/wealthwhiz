import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();

  TransactionType _type = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.other;
  DateTime _date = DateTime.now();
  File? _receiptImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
      _date = widget.transaction!.date;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes ?? '';
      if (widget.transaction!.receiptPath != null) {
        _receiptImage = File(widget.transaction!.receiptPath!);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture image')),
      );
    }
  }

  Future<String?> _saveReceiptImage() async {
    if (_receiptImage == null) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'receipt_${const Uuid().v4()}.jpg';
      final String filePath = '${directory.path}/$fileName';
      await _receiptImage!.copy(filePath);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final String? receiptPath = await _saveReceiptImage();
      final transaction = Transaction(
        id: widget.transaction?.id ?? const Uuid().v4(),
        userId: 'current_user_id', // TODO: Get from auth service
        description: _notesController.text.isEmpty
            ? 'No description'
            : _notesController.text,
        type: _type,
        category: _category,
        amount: double.parse(_amountController.text),
        date: _date,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        receiptPath: receiptPath ?? widget.transaction?.receiptPath,
        syncStatus: SyncStatus.pending,
      );

      // Save to local storage
      await TransactionService.instance.saveTransaction(transaction);

      // Try to sync with Firestore if online
      await TransactionService.instance.syncTransactions();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transaction')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteTransaction() async {
    if (widget.transaction == null) return;

    setState(() => _isSaving = true);

    try {
      await TransactionService.instance
          .deleteTransaction(widget.transaction!.id);
      await TransactionService.instance.syncTransactions();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete transaction')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isSaving ? null : _deleteTransaction,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          children: [
            // Transaction Type
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (Set<TransactionType> selected) {
                setState(() {
                  _type = selected.first;
                  // Reset category when switching type
                  _category = TransactionCategory.other;
                });
              },
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Category
            DropdownButtonFormField<TransactionCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: TransactionCategory.values
                  .where((category) =>
                      category == TransactionCategory.other ||
                      (_type == TransactionType.expense
                          ? category != TransactionCategory.salary &&
                              category != TransactionCategory.freelance &&
                              category != TransactionCategory.business
                          : category == TransactionCategory.salary ||
                              category == TransactionCategory.freelance ||
                              category == TransactionCategory.business))
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.name),
                      ))
                  .toList(),
              onChanged: (TransactionCategory? value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                '${_date.day}/${_date.month}/${_date.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Receipt Image
            Card(
              child: InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: _receiptImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _receiptImage!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() => _receiptImage = null);
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt, size: 48),
                            SizedBox(height: 8),
                            Text('Add Receipt'),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: FilledButton(
            onPressed: _isSaving ? null : _saveTransaction,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save'),
          ),
        ),
      ),
    );
  }
}
