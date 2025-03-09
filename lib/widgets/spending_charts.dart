import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../utils/currency_formatter.dart';
import 'widgets.dart';
import 'dart:math' as math;
import 'dart:math' show max;

enum SpendingPeriod {
  weekly,
  monthly,
  yearly,
}

class SpendingCharts extends StatefulWidget {
  final List<Transaction> transactions;
  final double totalSpent;
  final Map<TransactionCategory, double> categorySpending;
  final Currency currency;

  const SpendingCharts({
    super.key,
    required this.transactions,
    required this.totalSpent,
    required this.categorySpending,
    required this.currency,
  });

  @override
  State<SpendingCharts> createState() => _SpendingChartsState();
}

class _SpendingChartsState extends State<SpendingCharts> {
  SpendingPeriod _selectedPeriod = SpendingPeriod.weekly;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPeriod();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentPeriod() {
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    double scrollPosition = 0;

    switch (_selectedPeriod) {
      case SpendingPeriod.weekly:
        scrollPosition = 6 * 50.0; // Current day position
        break;
      case SpendingPeriod.monthly:
        scrollPosition = (now.day - 1) * 40.0; // Current date position
        break;
      case SpendingPeriod.yearly:
        scrollPosition = (now.month - 1) * 60.0; // Current month position
        break;
    }

    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If there's no data, show a message
    if (widget.transactions.isEmpty || widget.totalSpent == 0) {
      return const CustomCard(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Center(
            child: Text('No spending data available'),
          ),
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMedium,
              0,
              AppConstants.paddingMedium,
              AppConstants.paddingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spending Analysis',
                  style: AppConstants.titleLarge,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPeriodButton(SpendingPeriod.weekly, 'W'),
                      _buildPeriodButton(SpendingPeriod.monthly, 'M'),
                      _buildPeriodButton(SpendingPeriod.yearly, 'Y'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          // Pie Chart Section
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(context),
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getPeriodLabel(),
                          style: AppConstants.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(
                              _getPeriodTotal(), widget.currency),
                          style: AppConstants.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Total Spent',
                          style: AppConstants.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildLegend(context),
          // Bar Chart Section
          const Divider(height: AppConstants.paddingLarge),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getChartTitle(),
                          style: AppConstants.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap bars for details',
                          style: AppConstants.bodySmall.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPeriodLabel(),
                        style: AppConstants.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              SizedBox(
                height: 150,
                child: Padding(
                  padding:
                      const EdgeInsets.only(right: AppConstants.paddingMedium),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _getChartWidth(),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxSpending() * 1.2,
                          minY: 0,
                          barTouchData: BarTouchData(
                            enabled: true,
                            handleBuiltInTouches: true,
                            touchTooltipData: BarTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              tooltipMargin: 8,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  CurrencyFormatter.format(
                                      rod.toY, widget.currency),
                                  AppConstants.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: max(
                                    1,
                                    (_selectedPeriod == SpendingPeriod.monthly
                                            ? 5
                                            : 1)
                                        .toDouble()),
                                getTitlesWidget: (value, meta) {
                                  if (_selectedPeriod ==
                                      SpendingPeriod.monthly) {
                                    if (value % 5 == 0) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: AppConstants.bodySmall,
                                      );
                                    }
                                  } else {
                                    return Text(
                                      value.toInt().toString(),
                                      style: AppConstants.bodySmall,
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 46,
                                interval: max(1, _getMaxSpending() / 4),
                                getTitlesWidget: (value, meta) =>
                                    _getLeftTitles(context, value, meta),
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _getMaxSpending() / 4,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Theme.of(context).dividerColor,
                                strokeWidth: 0.5,
                                dashArray: [5, 5],
                              );
                            },
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                              left: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          barGroups: _buildBarGroups(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedPeriod) {
      case SpendingPeriod.weekly:
        return 'Weekly Spending';
      case SpendingPeriod.monthly:
        return 'Monthly Spending';
      case SpendingPeriod.yearly:
        return 'Yearly Spending';
    }
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case SpendingPeriod.weekly:
        return 'Last 7 Days';
      case SpendingPeriod.monthly:
        return '${now.month}/${now.year}';
      case SpendingPeriod.yearly:
        return now.year.toString();
    }
  }

  double _getPeriodTotal() {
    final now = DateTime.now();
    double total = 0;

    for (var transaction in widget.transactions) {
      if (transaction.type == TransactionType.expense) {
        final difference = now.difference(transaction.date);
        bool shouldInclude = false;

        switch (_selectedPeriod) {
          case SpendingPeriod.weekly:
            shouldInclude = difference.inDays < 7;
            break;
          case SpendingPeriod.monthly:
            shouldInclude = transaction.date.year == now.year &&
                transaction.date.month == now.month;
            break;
          case SpendingPeriod.yearly:
            shouldInclude = transaction.date.year == now.year;
            break;
        }

        if (shouldInclude) {
          total += transaction.amount;
        }
      }
    }

    return total;
  }

  Map<TransactionCategory, double> _getPeriodSpending() {
    final now = DateTime.now();
    final Map<TransactionCategory, double> spending = {};

    for (var transaction in widget.transactions) {
      if (transaction.type == TransactionType.expense) {
        final difference = now.difference(transaction.date);
        bool shouldInclude = false;

        switch (_selectedPeriod) {
          case SpendingPeriod.weekly:
            shouldInclude = difference.inDays < 7;
            break;
          case SpendingPeriod.monthly:
            shouldInclude = transaction.date.year == now.year &&
                transaction.date.month == now.month;
            break;
          case SpendingPeriod.yearly:
            shouldInclude = transaction.date.year == now.year;
            break;
        }

        if (shouldInclude) {
          spending[transaction.category] =
              (spending[transaction.category] ?? 0) + transaction.amount;
        }
      }
    }

    return spending;
  }

  List<PieChartSectionData> _buildPieChartSections(BuildContext context) {
    final List<PieChartSectionData> sections = [];
    final theme = Theme.of(context);
    final periodSpending = _getPeriodSpending();
    final total = _getPeriodTotal();

    // Sort categories by amount (descending)
    final sortedEntries = periodSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final category = entry.key;
      final amount = entry.value;

      final double percentage = total > 0 ? (amount / total) * 100 : 0;
      final bool isLargeSection = percentage > 10;

      // Calculate a slightly larger radius for the largest sections
      final double radius = isLargeSection ? 55 : 50;

      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(category, theme),
          value: percentage,
          title: isLargeSection ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: radius,
          titleStyle: AppConstants.bodySmall.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          showTitle: isLargeSection,
          badgeWidget: isLargeSection
              ? null
              : percentage > 5
                  ? _buildSmallBadge(context, category)
                  : null,
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }

    return sections;
  }

  Widget? _buildSmallBadge(BuildContext context, TransactionCategory category) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: _getCategoryColor(category, Theme.of(context)),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.background,
          width: 0.5,
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final periodSpending = _getPeriodSpending();
    final total = _getPeriodTotal();

    // Sort categories by amount (descending)
    final sortedCategories = periodSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      child: Wrap(
        spacing: AppConstants.paddingMedium,
        runSpacing: AppConstants.paddingSmall,
        alignment: WrapAlignment.center,
        children: sortedCategories.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage =
              total > 0 ? (amount / total * 100).toStringAsFixed(1) : '0.0';

          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category, theme),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatCategoryName(category.toString()),
                  style: AppConstants.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$percentage%',
                  style: AppConstants.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatCategoryName(String category) {
    final name = category.split('.').last;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  Color _getCategoryColor(TransactionCategory category, ThemeData theme) {
    switch (category) {
      case TransactionCategory.food:
        return Colors.orange;
      case TransactionCategory.shopping:
        return Colors.blue;
      case TransactionCategory.entertainment:
        return Colors.purple;
      case TransactionCategory.utilities:
        return Colors.green;
      case TransactionCategory.transportation:
        return Colors.red;
      case TransactionCategory.health:
        return Colors.teal;
      case TransactionCategory.education:
        return Colors.indigo;
      case TransactionCategory.salary:
        return Colors.amber;
      case TransactionCategory.travel:
        return Colors.cyan;
      case TransactionCategory.housing:
        return Colors.deepPurple;
      case TransactionCategory.investment:
        return Colors.brown;
      case TransactionCategory.freelance:
        return Colors.lightBlue;
      case TransactionCategory.business:
        return Colors.deepOrange;
      case TransactionCategory.gifts:
        return Colors.pink;
      case TransactionCategory.other:
        return Colors.grey;
    }
  }

  List<BarChartGroupData> _buildBarGroups(BuildContext context) {
    final spendingData = _getBarChartData();
    final List<BarChartGroupData> barGroups = [];
    final theme = Theme.of(context);
    final maxSpending = spendingData.isEmpty
        ? 0
        : spendingData.reduce((max, value) => value > max ? value : max);

    // Calculate bar width based on the period
    final double barWidth = _selectedPeriod == SpendingPeriod.yearly
        ? 30
        : _selectedPeriod == SpendingPeriod.weekly
            ? 20
            : 16;

    // Define color ranges for spending levels
    final List<Color> spendingColors = [
      Colors.green.shade300,
      Colors.blue.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
    ];

    for (int i = 0; i < spendingData.length; i++) {
      final double spending = spendingData[i];
      final bool isLatest = i == spendingData.length - 1;
      final bool isCurrentPeriod = _isCurrentPeriod(i);

      final double spendingRatio = maxSpending > 0 ? spending / maxSpending : 0;
      final int colorIndex =
          (spendingRatio * (spendingColors.length - 1)).floor();
      final Color baseColor = isCurrentPeriod
          ? theme.colorScheme.primary
          : spendingColors[colorIndex];

      final List<Color> barColors = [
        baseColor,
        baseColor.withOpacity(0.7),
      ];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: spending,
              gradient: LinearGradient(
                colors: barColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              width: barWidth,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
                bottom: Radius.circular(1),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxSpending * 1.2,
                gradient: LinearGradient(
                  colors: [
                    baseColor.withOpacity(0.05),
                    baseColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  List<double> _getBarChartData() {
    final now = DateTime.now();
    List<double> data = [];

    switch (_selectedPeriod) {
      case SpendingPeriod.weekly:
        data = List.filled(7, 0); // Last 7 days
        for (var transaction in widget.transactions) {
          if (transaction.type == TransactionType.expense) {
            final daysAgo = now.difference(transaction.date).inDays;
            if (daysAgo < 7) {
              data[6 - daysAgo] += transaction.amount;
            }
          }
        }
        break;

      case SpendingPeriod.monthly:
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        data = List.filled(daysInMonth, 0);
        for (var transaction in widget.transactions) {
          if (transaction.type == TransactionType.expense &&
              transaction.date.year == now.year &&
              transaction.date.month == now.month) {
            data[transaction.date.day - 1] += transaction.amount;
          }
        }
        break;

      case SpendingPeriod.yearly:
        data = List.filled(12, 0); // 12 months
        for (var transaction in widget.transactions) {
          if (transaction.type == TransactionType.expense &&
              transaction.date.year == now.year) {
            data[transaction.date.month - 1] += transaction.amount;
          }
        }
        break;
    }

    return data;
  }

  Widget _getLeftTitles(BuildContext context, double value, TitleMeta meta) {
    if (value == 0) {
      return const SizedBox.shrink();
    }

    final textStyle = AppConstants.bodySmall.copyWith(
      fontSize: 10,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        CurrencyFormatter.formatCompact(value, widget.currency),
        style: textStyle,
      ),
    );
  }

  Widget _getBottomTitles(BuildContext context, double value, TitleMeta meta) {
    final textStyle = AppConstants.bodySmall.copyWith(
      fontSize: 10,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    );

    String label = '';
    bool isLatest = false;
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case SpendingPeriod.weekly:
        final date = now.subtract(Duration(days: (6 - value).toInt()));
        label = _getDayName(date.weekday);
        isLatest = value == 6;
        break;

      case SpendingPeriod.monthly:
        final date = DateTime(now.year, now.month, value.toInt() + 1);
        label = '${date.day} ${_getShortMonthName(date.month)}';
        isLatest = value == now.day - 1;
        break;

      case SpendingPeriod.yearly:
        label = _getShortMonthName(value.toInt() + 1);
        isLatest = value == now.month - 1;
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        isLatest ? 'Now' : label,
        style: textStyle.copyWith(
          fontWeight: isLatest ? FontWeight.bold : null,
          color: isLatest
              ? Theme.of(context).colorScheme.primary
              : textStyle.color,
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'T';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      case DateTime.sunday:
        return 'S';
      default:
        return '';
    }
  }

  double _getMaxSpending() {
    final spendingData = _getBarChartData();
    return spendingData.isEmpty
        ? 100
        : max(
            1, spendingData.reduce((max, value) => value > max ? value : max));
  }

  Widget _buildPeriodButton(SpendingPeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppConstants.bodySmall.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  double _getChartWidth() {
    // Get the number of bars
    final int barCount = _getBarChartData().length;

    // Calculate width based on period and number of bars
    switch (_selectedPeriod) {
      case SpendingPeriod.weekly:
        return math.max(MediaQuery.of(context).size.width, barCount * 50.0);

      case SpendingPeriod.monthly:
        return math.max(MediaQuery.of(context).size.width, barCount * 40.0);

      case SpendingPeriod.yearly:
        return math.max(MediaQuery.of(context).size.width,
            barCount * 60.0); // Wider bars for yearly view
    }
  }

  String _getShortMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return '';
    }
  }

  bool _isCurrentPeriod(int index) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case SpendingPeriod.weekly:
        return index == 6; // Last index represents today
      case SpendingPeriod.monthly:
        return index == now.day - 1; // Current day of month (0-based index)
      case SpendingPeriod.yearly:
        return index == now.month - 1; // Current month (0-based index)
    }
  }

  void setState(VoidCallback fn) {
    super.setState(fn);
    // Schedule scroll after state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPeriod();
    });
  }
}
