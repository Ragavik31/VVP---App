import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_client.dart';
import '../auth/auth_provider.dart';
import '../services/socket_service.dart';

class AdminSalesAnalyticsScreen extends StatefulWidget {
  const AdminSalesAnalyticsScreen({super.key});

  @override
  State<AdminSalesAnalyticsScreen> createState() => _AdminSalesAnalyticsScreenState();
}

class _AdminSalesAnalyticsScreenState extends State<AdminSalesAnalyticsScreen> {
  bool _isLoading = false;
  String? _error;
  String _dateRange = 'Month'; // Today, Week, Month

  // Data maps
  Map<String, dynamic> _kpis = {'totalRevenue': 0, 'outstandingReceivables': 0, 'activeStaffLoad': []};
  List<dynamic> _collections = [];
  List<dynamic> _topProducts = [];
  List<dynamic> _topClients = [];
  List<dynamic> _staffEfficiency = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        SocketService().connect(token: auth.token!);
        // Listen for real-time updates to refresh
        SocketService().on('order:created', (_) => _loadAnalytics());
        SocketService().on('order:status_changed', (_) => _loadAnalytics());
      }
    });
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ApiClient.get('/admin/analytics?dateRange=$_dateRange');
      if (res is Map<String, dynamic> && res['success'] == true) {
        final data = res['data'];
        setState(() {
          _kpis = data['kpis'] ?? {};
          _collections = data['collections'] ?? [];
          _topProducts = data['topProducts'] ?? [];
          _topClients = data['topClients'] ?? [];
          _staffEfficiency = data['staffEfficiency'] ?? [];
        });
      } else {
        throw Exception('Failed to load analytics: ${res['message']}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Admin Sales Analytics', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4361EE),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Report',
            onPressed: () async {
               if (_collections.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('No collection data to export.')),
                 );
                 return;
               }
               await _exportSalesReport();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: const Color(0xFF4361EE),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateFilter(),
              const SizedBox(height: 20),
              
              if (_error != null) _buildErrorCard(),
              
              if (_isLoading && _kpis['totalRevenue'] == 0)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF4361EE)),
                ))
              else ...[
                _buildKPISection(),
                const SizedBox(height: 24),
                _buildPaymentTrackerSection(),
                const SizedBox(height: 24),
                _buildProductClientAnalytics(),
                const SizedBox(height: 24),
                _buildStaffEfficiencyChart(),
                const SizedBox(height: 80), // padding at bottom
              ]
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportSalesReport() async {
    try {
      if (_collections.isEmpty) return;
      
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        ['Client Name', 'Total Amount', 'Due Date', 'Status'],
      ];

      for (var col in _collections) {
        final clientName = col['clientName'] ?? 'Unknown';
        final amount = col['totalPrice'] ?? 0;
        final status = col['paymentStatus'] ?? 'unpaid';
        final dueDateStr = col['paymentDueDate'];
        
        String dateTxt = 'No Due Date';
        if (dueDateStr != null) {
          try {
            final d = DateTime.parse(dueDateStr).toLocal();
            dateTxt = DateFormat('yyyy-MM-dd').format(d);
          } catch (_) {}
        }
        
        csvData.add([clientName, amount, dateTxt, status.toString().toUpperCase()]);
      }

      String csv = const CsvEncoder().convert(csvData);

      if (kIsWeb) {
        // Not handled for web explicitly here, but would use html
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export unsupported on web version currently.')),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/collections_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report exported to $path'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              final uri = Uri.file(path);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Widget _buildDateFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)),
        ),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['Today', 'Week', 'Month'].map((range) {
              final isSelected = _dateRange == range;
              return GestureDetector(
                onTap: () {
                  setState(() => _dateRange = range);
                  _loadAnalytics();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4361EE) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    range,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF6B7A9D),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildKPISection() {
    double totalRev = (_kpis['totalRevenue'] ?? 0).toDouble();
    double outRec = (_kpis['outstandingReceivables'] ?? 0).toDouble();
    
    // Calculate total active staff load
    int activeLoad = 0;
    if (_kpis['activeStaffLoad'] is List) {
       for (var staff in _kpis['activeStaffLoad']) {
         activeLoad += (staff['count'] ?? 0) as int;
       }
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      children: [
        _buildStatCard(
          title: 'Total Revenue',
          value: _currencyFormat.format(totalRev),
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF06D6A0),
          textColor: Colors.white,
          isOutlined: false,
        ),
        _buildStatCard(
          title: 'Unpaid Orders',
          value: _currencyFormat.format(outRec),
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFEF233C),
          textColor: Colors.white,
          isOutlined: false,
        ),
        _buildStatCard(
          title: 'Active Staff',
          value: '$activeLoad',
          icon: Icons.groups_rounded,
          color: Colors.white,
          textColor: const Color(0xFF0D1B2A),
          iconBgColor: const Color(0xFFEEF2FF),
          iconColor: const Color(0xFF4361EE),
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
    Color? iconBgColor,
    Color? iconColor,
    bool isOutlined = false,
  }) {
    final bool isDark = textColor == Colors.white;
    return Card(
      elevation: isOutlined ? 0 : 4,
      color: isOutlined ? Colors.transparent : color,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isOutlined ? BorderSide(color: const Color(0xFF4361EE).withOpacity(0.3), width: 1.5) : BorderSide.none,
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor ?? Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF6B7A9D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTrackerSection() {
    return _buildSectionCard(
      title: 'High-Priority Collections',
      icon: Icons.warning_rounded,
      iconColor: const Color(0xFFFFB703),
      child: _collections.isEmpty
          ? const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No overdue or upcoming collections.', style: TextStyle(color: Color(0xFF6B7A9D))),
            ))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _collections.length,
              itemBuilder: (context, index) {
                final collection = _collections[index];
                final clientName = collection['clientName'] ?? 'Unknown';
                final amount = collection['totalPrice'] ?? 0;
                final status = collection['paymentStatus'] ?? 'unpaid';
                final dueDateStr = collection['paymentDueDate'];
                
                String dateTxt = 'No Due Date';
                DateTime? dueDate;
                if (dueDateStr != null) {
                  try {
                    dueDate = DateTime.parse(dueDateStr).toLocal();
                    dateTxt = DateFormat('MMM dd, yyyy').format(dueDate);
                  } catch (_) {}
                }

                final now = DateTime.now();
                final isOverdue = status == 'overdue' || (dueDate != null && dueDate.isBefore(now));
                final daysUntilDue = dueDate != null ? dueDate.difference(now).inDays : 0;
                
                String urgencyText = isOverdue ? 'OVERDUE' : (daysUntilDue == 0 ? 'DUE TODAY' : 'DUE IN $daysUntilDue DAYS');

                return Card(
                  elevation: 0,
                  color: isOverdue ? const Color(0xFFFFE8EC) : const Color(0xFFFFF8E1),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isOverdue ? const BorderSide(color: Color(0xFFEF233C), width: 1) : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                       children: [
                          Expanded(child: Text(clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOverdue ? const Color(0xFFEF233C) : const Color(0xFFFFB703),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              urgencyText,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)
                            ),
                          )
                       ]
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Due: $dateTxt', style: TextStyle(color: isOverdue ? const Color(0xFFEF233C) : const Color(0xFFD4A373), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_currencyFormat.format(amount), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isOverdue ? const Color(0xFFEF233C) : const Color(0xFF0D1B2A))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProductClientAnalytics() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSectionCard(
            title: 'Top 5 Products',
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFF4361EE),
            child: _topProducts.isEmpty
                ? const Text('No product data.', style: TextStyle(color: Color(0xFF6B7A9D)))
                : Column(
                    children: _topProducts.asMap().entries.map((e) {
                      final i = e.key;
                      final prod = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text('#${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4361EE))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(prod['name'] ?? 'Product', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            Text('${prod['quantitySold']} sold', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSectionCard(
            title: 'Top 5 Clients',
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF06D6A0),
            child: _topClients.isEmpty
                ? const Text('No client data.', style: TextStyle(color: Color(0xFF6B7A9D)))
                : Column(
                    children: _topClients.asMap().entries.map((e) {
                      final i = e.key;
                      final client = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text('#${i+1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF06D6A0))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(client['clientName'] ?? 'Client', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            Text(_currencyFormat.format(client['totalSpend'] ?? 0), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffEfficiencyChart() {
    return _buildSectionCard(
      title: 'Staff Efficiency & Order Volume',
      icon: Icons.bar_chart_rounded,
      iconColor: const Color(0xFF7209B7),
      child: _staffEfficiency.isEmpty
          ? const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No staff data available for this range.', style: TextStyle(color: Color(0xFF6B7A9D))),
            ))
          : Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ChartLegend(color: Color(0xFF4361EE), text: 'Order Volume'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxOrderVolume() * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF0D1B2A),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final staff = _staffEfficiency[group.x];
                            return BarTooltipItem(
                              '${staff['staff']} \n${rod.toY.round()} Orders\nAvg: ${staff['avgTime']} mins',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= _staffEfficiency.length) return const SizedBox.shrink();
                              final staffName = _staffEfficiency[value.toInt()]['staff'] ?? 'Staff';
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(staffName.toString().split(' ').first, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7A9D))),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) return const SizedBox.shrink();
                              return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF6B7A9D)));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFE8ECFF), strokeWidth: 1),
                      ),
                      barGroups: _staffEfficiency.asMap().entries.map((e) {
                         return BarChartGroupData(
                           x: e.key,
                           barRods: [
                             BarChartRodData(
                               toY: (e.value['count'] ?? 0).toDouble(),
                               color: const Color(0xFF4361EE),
                               width: 22,
                               borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                             )
                           ]
                         );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Detailed List View below chart
                ..._staffEfficiency.map((staff) {
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 8),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(staff['staff'] ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D1B2A))),
                         Text('Avg Accept Time: ${staff['avgTime'] != null ? '${staff['avgTime']} mins' : 'N/A'}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D))),
                       ],
                     ),
                   );
                }),
              ],
            ),
    );
  }

  double _getMaxOrderVolume() {
    double max = 0;
    for (var s in _staffEfficiency) {
      final vol = (s['count'] ?? 0).toDouble();
      if (vol > max) max = vol;
    }
    return max == 0 ? 5 : max;
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Color iconColor, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A)))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: const Color(0xFFFFE8EC), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF233C), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF233C), fontSize: 13))),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String text;
  const _ChartLegend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A9D), fontWeight: FontWeight.w600)),
      ],
    );
  }
}
