import { useState } from "react";
import Layout from "../components/Layout";
import { ReceiptText, ArrowUpRight, ArrowDownLeft, Clock, CheckCircle2, AlertCircle, X, CreditCard, ShieldCheck } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { useToast } from "../components/Toast";

export default function ResidentBills() {
  const { showToast } = useToast();
  const [isPayModalOpen, setIsPayModalOpen] = useState(false);
  const [isPaying, setIsPaying] = useState(false);

  const bills = [
    { id: 1, title: "Monthly Maintenance", amount: "$150.00", date: "Mar 01, 2026", status: "Paid", type: "maintenance" },
    { id: 2, title: "Electricity Bill", amount: "$85.40", date: "Feb 28, 2026", status: "Pending", type: "utility" },
    { id: 3, title: "Water Usage", amount: "$32.10", date: "Feb 25, 2026", status: "Paid", type: "utility" },
    { id: 4, title: "Parking Fee", amount: "$50.00", date: "Feb 20, 2026", status: "Overdue", type: "parking" },
  ];

  const handlePayment = () => {
    setIsPaying(true);
    setTimeout(() => {
      setIsPaying(false);
      setIsPayModalOpen(false);
      showToast("Payment successful! Your balance has been updated.", "success");
    }, 2000);
  };

  return (
    <Layout title="My Bills" role="resident">
      <div className="p-4">
        <div className="bg-[#137fec] rounded-2xl p-6 text-white mb-6 shadow-lg shadow-[#137fec]/20">
          <p className="text-xs font-bold uppercase tracking-widest opacity-80">Total Outstanding</p>
          <h2 className="text-3xl font-extrabold mt-1">$135.40</h2>
          <div className="flex gap-3 mt-6">
            <button 
              onClick={() => setIsPayModalOpen(true)}
              className="flex-1 bg-white text-[#137fec] py-3 rounded-xl font-bold text-sm active:scale-[0.98] transition-all"
            >
              Pay Now
            </button>
            <button 
              onClick={() => showToast("Downloading statement...", "info")}
              className="flex-1 bg-white/20 backdrop-blur-md text-white py-3 rounded-xl font-bold text-sm active:scale-[0.98] transition-all"
            >
              Statement
            </button>
          </div>
        </div>

        <div className="space-y-4">
          <h3 className="text-sm font-bold uppercase tracking-widest text-slate-400 px-1">Recent Transactions</h3>
          <div className="space-y-3">
            {bills.map((bill) => (
              <motion.div 
                key={bill.id}
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                onClick={() => showToast(`Viewing details for ${bill.title}`, "info")}
                className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center gap-4 cursor-pointer active:scale-[0.98] transition-all"
              >
                <div className={`size-10 rounded-full flex items-center justify-center shrink-0 ${
                  bill.status === 'Paid' ? 'bg-green-100 text-green-600' : 
                  bill.status === 'Pending' ? 'orange-100 text-orange-600' : 
                  'bg-red-100 text-red-600'
                }`}>
                  {bill.status === 'Paid' ? <ArrowDownLeft className="w-5 h-5" /> : <ArrowUpRight className="w-5 h-5" />}
                </div>
                <div className="flex-1 min-w-0">
                  <h4 className="text-sm font-bold truncate">{bill.title}</h4>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">{bill.date}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold">{bill.amount}</p>
                  <span className={`text-[9px] font-bold uppercase tracking-tighter ${
                    bill.status === 'Paid' ? 'text-green-500' : 
                    bill.status === 'Pending' ? 'text-orange-500' : 
                    'text-red-500'
                  }`}>
                    {bill.status}
                  </span>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </div>

      {/* Payment Modal */}
      <AnimatePresence>
        {isPayModalOpen && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsPayModalOpen(false)}
              className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[100] max-w-md mx-auto"
            />
            <motion.div 
              initial={{ y: "100%" }}
              animate={{ y: 0 }}
              exit={{ y: "100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-x-0 bottom-0 max-w-md mx-auto bg-white dark:bg-[#101922] rounded-t-[32px] z-[110] p-6 pb-10 shadow-2xl"
            >
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <div className="size-10 rounded-xl bg-[#137fec]/10 text-[#137fec] flex items-center justify-center">
                    <CreditCard className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">Secure Payment</h3>
                    <p className="text-xs text-slate-500 font-medium">Total: $135.40</p>
                  </div>
                </div>
                <button onClick={() => setIsPayModalOpen(false)} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full transition-colors">
                  <X className="w-5 h-5 text-slate-400" />
                </button>
              </div>

              <div className="space-y-4 mb-8">
                <div className="p-4 rounded-2xl border border-[#137fec] bg-[#137fec]/5 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="size-10 rounded-lg bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 flex items-center justify-center">
                      <img src="https://upload.wikimedia.org/wikipedia/commons/5/5e/Visa_Inc._logo.svg" alt="Visa" className="w-8" />
                    </div>
                    <div>
                      <p className="text-sm font-bold">Visa •••• 4242</p>
                      <p className="text-[10px] text-slate-500 font-medium uppercase tracking-wider">Default Payment Method</p>
                    </div>
                  </div>
                  <CheckCircle2 className="w-5 h-5 text-[#137fec]" />
                </div>

                <div className="flex items-center gap-2 px-2 py-1 bg-slate-50 dark:bg-slate-800/50 rounded-lg">
                  <ShieldCheck className="w-4 h-4 text-green-500" />
                  <p className="text-[10px] text-slate-500 font-medium">Your transaction is encrypted and secure.</p>
                </div>
              </div>

              <button 
                disabled={isPaying}
                onClick={handlePayment}
                className="w-full py-4 bg-[#137fec] text-white rounded-2xl font-bold text-sm shadow-lg shadow-blue-500/20 active:scale-[0.98] transition-all disabled:opacity-50 disabled:active:scale-100 flex items-center justify-center gap-2"
              >
                {isPaying ? (
                  <div className="size-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  "Pay $135.40"
                )}
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </Layout>
  );
}
