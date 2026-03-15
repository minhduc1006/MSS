import { useState } from "react";
import Layout from "../components/Layout";
import ActionGrid from "../components/ActionGrid";
import { useToast } from "../components/Toast";
import { Search, Edit2, Eye, Trash2, Users } from "lucide-react";
import { motion } from "motion/react";

export default function ResidentList() {
  const { showToast } = useToast();
  const [residents] = useState([
    { id: 1, name: "Alex Thompson", unit: "402B", lease: "Active", email: "alex.t@example.com", status: "Active", avatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuD58XpZ0S7PBEkVGRVsjDsAg4IYR9GoPrf3o5FalkWBnLf-ncat1ykwM4n2X-gp7UtFWNy5OiyivaMikAy0qXEoaBzFILWaWy2bPCKQj1XEE-GnXZaHMZRBnzGmsxUNT51nha-5XAOXgJT3HF1U5oDF6GBZzwqoPBh0hLVJa6768oeddnTinJXX3lN-PsO-uugg_YBgSN8X1pHV1j1q8Jb4b5TUOU5F_GDrpaWL4grlJmLesbA0j4f4ZON6JPCQvIWyEI3HaiQ1MTU" },
    { id: 2, name: "Sarah Jenkins", unit: "115A", lease: "Ending soon", email: "s.jenkins@corp.com", status: "Active", avatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuAC-73rvqrdXVS-OdVjsa79mISrAdgk8Oc9mN4UakWYFm4Ppa9RxCKsgr89ncnLmRTunB7We8zMePV4njisVn7CP9jtkwpLoYlN14DmPH12oIVPMb1IXNi_DvemDb4PWxBTXG1ZH7HfQmVg8DJNOmti8s3ssNUKt8kFc8fL8dSQXmiHUDizRP-DbEENcEBZ297iLz8cTD8AhJ9BWqd6vXcZXNpD5xdFbxedkYEoHz6BYdNbBxBqnmKbBN-nOD9-9f0TGXlYFS7iep4" },
    { id: 3, name: "Michael Rivera", unit: "303C", lease: "Move-out", email: "m.rivera@web.com", status: "Inactive", avatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuAygxCHf6mgPHIJ55VGvQsqO-Bymt7C_nAOoPo-k9NCTrUkGnIt3-kNSSs54PHHGhmOjciNatzuMfPlvebNp9Gtz9kTfcJcClTnGHfuMWlztYeCfiptAy_dY0SDUTKoEd4KlGnlA0SGBfZZW83oFNrtjUErqj6IOEpho9bVkibTBqbz6b8NITImQ8xY6iGYLn5NHROM0S4e3VRyOgQ2uRWTZhG2XUNRdd0cEKKHTtbS5NOeAi4-OYZSyDzE0yHW44facLgdkoPO-NU" },
  ]);

  const handleAction = (action: string) => {
    console.log(`Resident Action: ${action}`);
  };

  const handleItemAction = (name: string, action: string) => {
    showToast(`${action} performed on ${name}`, "success");
  };

  return (
    <Layout title="Residents" role="admin">
      <div className="p-4">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Users className="text-[#137fec] w-6 h-6" />
            <h1 className="text-xl font-extrabold tracking-tight">Resident Management</h1>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden mb-6">
          <div className="px-4 py-3 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/50">
            <h3 className="text-xs font-bold uppercase tracking-widest text-slate-400">Resident Operations</h3>
          </div>
          <ActionGrid onAction={handleAction} />
        </div>

        <div className="pb-3">
          <div className="flex w-full items-stretch rounded-lg h-11 border border-[#137fec]/10 shadow-sm overflow-hidden bg-white dark:bg-slate-800">
            <div className="text-slate-400 flex items-center justify-center pl-4">
              <Search className="w-5 h-5" />
            </div>
            <input 
              className="flex w-full min-w-0 flex-1 resize-none overflow-hidden text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border-none bg-transparent h-full placeholder:text-slate-400 px-4 pl-2 text-sm font-medium" 
              placeholder="Search by name or unit..." 
            />
          </div>
        </div>

        <div className="space-y-3">
          {residents.map((resident) => (
            <motion.div 
              key={resident.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col gap-3"
            >
              <div className="flex justify-between items-start">
                <div className="flex gap-3 items-center">
                  <img className="size-10 rounded-full bg-slate-100 object-cover" src={resident.avatar} alt={resident.name} />
                  <div>
                    <h3 className="font-bold text-sm">{resident.name}</h3>
                    <p className="text-xs text-slate-500 dark:text-slate-400">Unit {resident.unit} • Lease: {resident.lease}</p>
                  </div>
                </div>
                <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${resident.status === 'Active' ? 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400'}`}>
                  {resident.status}
                </span>
              </div>
              <div className="flex items-center justify-between pt-2 border-t border-slate-50 dark:border-slate-800">
                <div className="flex flex-col">
                  <span className="text-[10px] text-slate-400 uppercase font-bold tracking-widest">Contact</span>
                  <span className="text-xs font-medium">{resident.email}</span>
                </div>
                <div className="flex gap-2">
                  <button 
                    onClick={() => handleItemAction(resident.name, "Edit")}
                    className="size-8 flex items-center justify-center rounded-lg bg-[#137fec]/10 text-[#137fec]"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                  <button 
                    onClick={() => handleItemAction(resident.name, "View Details")}
                    className="size-8 flex items-center justify-center rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400"
                  >
                    <Eye className="w-4 h-4" />
                  </button>
                  <button 
                    onClick={() => handleItemAction(resident.name, "Delete")}
                    className="size-8 flex items-center justify-center rounded-lg bg-red-50 dark:bg-red-900/10 text-red-500"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </Layout>
  );
}
