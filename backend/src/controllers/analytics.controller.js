const Order = require('../models/order.model');

// ======================================================
// GET ANALYTICS DASHBOARD (ADMIN)
// ======================================================
const getAnalyticsDashboard = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        // Build date filter if provided
        let dateFilter = {};
        if (startDate || endDate) {
            dateFilter.createdAt = {};
            if (startDate) dateFilter.createdAt.$gte = new Date(startDate);
            if (endDate) dateFilter.createdAt.$lte = new Date(endDate);
        }

        // 1. KPIs
        // Total Revenue (paid orders)
        const revenueAgg = await Order.aggregate([
            { $match: { ...dateFilter, paymentStatus: 'paid' } },
            { $group: { _id: null, totalRevenue: { $sum: '$totalPrice' } } }
        ]);
        const totalRevenue = revenueAgg.length > 0 ? revenueAgg[0].totalRevenue : 0;

        // Outstanding Receivables (cash and unpaid orders)
        const outstandingAgg = await Order.aggregate([
            { $match: { ...dateFilter, paymentMethod: 'cash', paymentStatus: 'unpaid' } },
            { $group: { _id: null, totalOutstanding: { $sum: '$totalPrice' } } }
        ]);
        const totalOutstanding = outstandingAgg.length > 0 ? outstandingAgg[0].totalOutstanding : 0;

        // Active Staff Load
        const activeStaffCountAgg = await Order.aggregate([
            { $match: { status: { $in: ['assigned', 'accepted'] } } },
            { $group: { _id: '$assignedTo', count: { $sum: 1 } } }
        ]);
        const activeStaffLoad = activeStaffCountAgg.reduce((acc, curr) => acc + curr.count, 0);

        // 2. Payment & Collection Tracker
        // Fetch orders overdue or due in next 7 days
        const now = new Date();
        const sevenDaysFromNow = new Date();
        sevenDaysFromNow.setDate(now.getDate() + 7);

        const collectionTracker = await Order.find({
            paymentMethod: 'cash',
            paymentStatus: 'unpaid',
            paymentDueDate: { $ne: null, $lte: sevenDaysFromNow }
        })
            .select('clientName clientCode totalPrice paymentDueDate paymentStatus status createdAt')
            .sort({ paymentDueDate: 1 });

        // 3. Product Analytics
        // Top 5 Products by quantity sold
        const topProducts = await Order.aggregate([
            { $match: dateFilter },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.vaccineId',
                    productName: { $first: '$items.vaccineName' },
                    quantitySold: { $sum: '$items.quantity' }
                }
            },
            { $sort: { quantitySold: -1 } },
            { $limit: 5 }
        ]);

        // Top Clients by spend
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

        // 4. Staff Efficiency Report
        // Avg time to accept order (delta between acceptedAt and assignedAt) in minutes
        const staffEfficiency = await Order.aggregate([
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
                    staffName: { $first: '$assignedStaffName' },
                    avgAcceptanceTimeMinutes: {
                        $avg: {
                            $divide: [
                                { $subtract: ['$acceptedAt', '$assignedAt'] },
                                1000 * 60 // convert milliseconds to minutes
                            ]
                        }
                    },
                    ordersDelivered: {
                        $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] }
                    },
                    totalAssigned: { $sum: 1 }
                }
            }
        ]);

        res.status(200).json({
            success: true,
            data: {
                kpis: {
                    totalRevenue,
                    totalOutstanding,
                    activeStaffLoad
                },
                collectionTracker,
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
