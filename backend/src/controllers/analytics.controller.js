const Order = require('../models/order.model');
const Product = require('../models/product.model');
const User = require('../models/user.model');

// Helper to get date based on dateRange (Today, Week, Month)
const getDateFilter = (dateRange) => {
    const now = new Date();
    if (dateRange === 'Today') {
        return new Date(now.setHours(0, 0, 0, 0));
    } else if (dateRange === 'Week') {
        return new Date(now.setDate(now.getDate() - 7));
    } else if (dateRange === 'Month') {
        return new Date(now.setMonth(now.getMonth() - 1));
    }
    return null;
};

exports.getAnalyticsDashboard = async (req, res) => {
    try {
        const { dateRange } = req.query;

        // 1. match stage for filtering based on Date Range
        const matchStage = {};
        const lowerBoundDate = getDateFilter(dateRange);
        if (lowerBoundDate) {
            matchStage.createdAt = { $gte: lowerBoundDate };
        }

        // 2. KPIs
        const kpiAggregation = await Order.aggregate([
            { $match: matchStage },
            {
                $group: {
                    _id: null,
                    totalRevenue: {
                        $sum: {
                            $cond: [{ $eq: ["$paymentStatus", "paid"] }, "$totalPrice", 0]
                        }
                    },
                    outstandingReceivables: {
                        $sum: {
                            $cond: [{ $in: ["$paymentStatus", ["unpaid", "overdue"]] }, "$totalPrice", 0]
                        }
                    }
                }
            }
        ]);

        const kpis = {
            totalRevenue: kpiAggregation[0]?.totalRevenue || 0,
            outstandingReceivables: kpiAggregation[0]?.outstandingReceivables || 0,
        };

        // Active Staff Load (Assigned but not Completed)
        const activeStaffLoad = await Order.aggregate([
            { $match: { ...matchStage, status: { $in: ["assigned", "accepted", "delivered"] } } }, // assuming delivered is still active until completed, or maybe just assigned and accepted
            {
                $group: {
                    _id: "$assignedTo",
                    staffName: { $first: "$assignedStaffName" },
                    activeOrders: { $sum: 1 }
                }
            },
            {
                $project: {
                    _id: 0,
                    staff: "$staffName",
                    count: "$activeOrders"
                }
            }
        ]);

        // 3. Payment & Collection Tracker (Due within 7 days or Overdue)
        const sevenDaysFromNow = new Date();
        sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

        // Instead of aggregating, find the documents because we want a list to show
        const collections = await Order.find({
            ...matchStage,
            paymentStatus: { $in: ["unpaid", "overdue"] },
            paymentDueDate: { $lte: sevenDaysFromNow }
        }).select('clientName totalPrice paymentDueDate paymentStatus').sort('paymentDueDate');

        // 4. Products & Client Analytics
        const topProducts = await Order.aggregate([
            { $match: matchStage },
            { $unwind: "$items" },
            {
                $group: {
                    _id: "$items.vaccineId",
                    name: { $first: "$items.vaccineName" },
                    frequency: { $sum: 1 },
                    quantitySold: { $sum: "$items.quantity" }
                }
            },
            { $sort: { frequency: -1 } },
            { $limit: 5 }
        ]);

        const topClients = await Order.aggregate([
            { $match: matchStage },
            {
                $group: {
                    _id: "$clientId",
                    clientName: { $first: "$clientName" },
                    totalSpend: { $sum: "$totalPrice" }
                }
            },
            { $sort: { totalSpend: -1 } },
            { $limit: 5 }
        ]);

        // 5. Staff Efficiency Report (Average Acceptance Time & Order Volume)
        const staffEfficiency = await Order.aggregate([
            { $match: { ...matchStage, assignedTo: { $ne: null } } },
            {
                $group: {
                    _id: "$assignedTo",
                    staffName: { $first: "$assignedStaffName" },
                    orderVolume: { $sum: 1 },
                    avgAcceptanceTimeMs: {
                        $avg: {
                            $cond: [
                                { $and: [{ $ne: ["$acceptedAt", null] }, { $ne: ["$assignedAt", null] }] },
                                { $subtract: ["$acceptedAt", "$assignedAt"] },
                                null
                            ]
                        }
                    }
                }
            },
            {
                $project: {
                    _id: 0,
                    staff: "$staffName",
                    count: "$orderVolume",
                    // Convert milliseconds to minutes
                    avgTime: {
                        $round: [{ $divide: ["$avgAcceptanceTimeMs", 1000 * 60] }, 2] // avgTime in minutes rounded to 2 decimals
                    }
                }
            }
        ]);

        res.status(200).json({
            success: true,
            data: {
                kpis: {
                    ...kpis,
                    activeStaffLoad
                },
                collections,
                topProducts,
                topClients,
                staffEfficiency
            }
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, message: 'Server error retrieving analytics' });
    }
};
