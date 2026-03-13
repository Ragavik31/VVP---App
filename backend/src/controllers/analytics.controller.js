const Order = require('../models/order.model');

// ======================================================
// GET ANALYTICS DASHBOARD (ADMIN)
// ======================================================
const getAnalyticsDashboard = async (req, res) => {
    try {
        const { dateRange } = req.query; // 'Today', 'Week', 'Month', 'All Time'

        // Build date filter
        let dateFilter = {};
        if (dateRange && dateRange !== 'All Time') {
            const start = new Date();
            start.setHours(0, 0, 0, 0); // start of today
            if (dateRange === 'Week') {
                start.setDate(start.getDate() - 7);
            } else if (dateRange === 'Month') {
                start.setDate(start.getDate() - 30);
            }
            dateFilter.createdAt = { $gte: start };
        }

        // 1. KPIs
        const revenueAgg = await Order.aggregate([
            { $match: { ...dateFilter, paymentStatus: 'paid' } },
            { $group: { _id: null, totalRevenue: { $sum: '$totalPrice' } } }
        ]);
        const totalRevenue = revenueAgg.length > 0 ? revenueAgg[0].totalRevenue : 0;

        const outstandingAgg = await Order.aggregate([
            { $match: { ...dateFilter, paymentMethod: 'cash', paymentStatus: 'unpaid' } },
            { $group: { _id: null, totalOutstanding: { $sum: '$totalPrice' } } }
        ]);
        const outstandingReceivables = outstandingAgg.length > 0 ? outstandingAgg[0].totalOutstanding : 0;

        const activeStaffLoad = await Order.aggregate([
            { $match: { status: { $in: ['assigned', 'accepted'] } } },
            { $group: { _id: '$assignedTo', count: { $sum: 1 }, staffName: { $first: '$assignedStaffName' } } }
        ]);

        // 2. Collections (Overdue or Due in next 7 days)
        const now = new Date();
        const sevenDaysFromNow = new Date();
        sevenDaysFromNow.setDate(now.getDate() + 7);

        const collections = await Order.find({
            paymentMethod: 'cash',
            paymentStatus: 'unpaid',
            paymentDueDate: { $ne: null, $lte: sevenDaysFromNow }
        })
            .select('clientName clientCode totalPrice paymentDueDate paymentStatus status createdAt')
            .sort({ paymentDueDate: 1 });

        // 3. Product & Client Analytics
        const topProductsRaw = await Order.aggregate([
            { $match: dateFilter },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.vaccineId',
                    name: { $first: '$items.vaccineName' },
                    quantitySold: { $sum: '$items.quantity' }
                }
            },
            { $sort: { quantitySold: -1 } },
            { $limit: 5 }
        ]);

        // Fallback if product name missing
        const topProducts = topProductsRaw.map(p => ({
            name: p.name || 'Unknown Item',
            quantitySold: p.quantitySold
        }));

        const topClients = await Order.aggregate([
            { $match: dateFilter },
            {
                $group: {
                    _id: '$clientId',
                    clientName: { $first: '$clientName' },
                    totalSpend: { $sum: '$totalPrice' }
                }
            },
            { $sort: { totalSpend: -1 } },
            { $limit: 5 }
        ]);

        // 4. Staff Efficiency
        const staffEfficiencyRaw = await Order.aggregate([
            {
                $match: {
                    ...dateFilter,
                    assignedAt: { $exists: true, $ne: null },
                    acceptedAt: { $exists: true, $ne: null },
                    assignedStaffName: { $exists: true, $ne: null }
                }
            },
            {
                $group: {
                    _id: '$assignedTo',
                    staff: { $first: '$assignedStaffName' },
                    avgTime: {
                        $avg: {
                            $divide: [
                                { $subtract: ['$acceptedAt', '$assignedAt'] },
                                1000 * 60 // convert to mins
                            ]
                        }
                    },
                    count: { $sum: 1 }
                }
            }
        ]);

        // Format avgTime to fixed string (e.g. "1.5")
        const staffEfficiency = staffEfficiencyRaw.map(s => ({
            staff: s.staff,
            avgTime: s.avgTime ? parseFloat(s.avgTime.toFixed(1)) : 0,
            count: s.count
        }));

        res.status(200).json({
            success: true,
            data: {
                kpis: {
                    totalRevenue,
                    outstandingReceivables,
                    activeStaffLoad
                },
                collections,
                topProducts,
                topClients,
                staffEfficiency
            }
        });
    } catch (error) {
        console.error('Error fetching analytics:', error);
        res.status(500).json({ success: false, message: 'Server error retrieving analytics' });
    }
};

module.exports = {
    getAnalyticsDashboard
};
