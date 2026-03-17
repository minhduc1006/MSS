import { useState } from "react";
import Layout from "../components/Layout";
import { Search, UserCheck, Mail, Phone, BadgeCheck, ShieldAlert } from "lucide-react";
import { motion } from "motion/react";

export default function StaffList() {
  const [staff] = useState([
    { id: 1, name: "David Miller", role: "Security Officer", shift: "Day", email: "d.miller@skyline.com", phone: "+1 (555) 123-4567", status: "On Duty", avatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuD58XpZ0S7PBEkVGRVsjDsAg4IYR9GoPrf3o5FalkWBnLf-ncat1ykwM4n2X-gp7UtFWNy5OiyivaMikAy0qXEoaBzFILWaWy2bPCKQj1XEE-GnXZaHMZRBnzGmsxUNT51nha-5XAOXgJT3HF1U5oDF6GBZzwqoPBh0hLVJa6768oeddnTinJXX3lN-PsO-uugg_YBgSN8X1pHV1j1q8Jb4b5TUOU5F_GDrpaWL4grlJmLesbA0j4f4ZON6JPCQvIWyEI3HaiQ1MTU" },
    { id: 2, name: "Sarah Connor", role: "Maintenance Lead", shift: "Night", email: "s.connor@skyline.com", phone: "+1 (555) 987-6543", status: "Off Duty", avatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuAC-73rvqrdXVS-OdVjsa79mISrAdgk8Oc9mN4UakWYFm4Ppa9RxCKsgr89ncnLmRTunB7We8zMePV4njisVn7CP9jtkwpLoYlN14DmPH12oIVPMb1IXNi_DvemDb4PWxBTXG1ZH7HfQmVg8DJNOmti8s3ssNUKt8kFc8fL8dSQXmiHUDizRP-DbEENcEBZ297iLz8cTD8AhJ9BWqd6vXcZXNpD5xdFbxedkYEoHz6BYdNbBxBqnmKbBN-nOD9-9f0TGXlYFS7iep4" },
    { id: 3, name: "Robert Wilson", role: "Concierge", shift: "Day", email: "r.wilson@skyline.com", phone: "+1 (555) 456-7890", status: "On Duty", avatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuAygxCHf6mgPHIJ55VGvQsqO-Bymt7C_nAOoPo-k9NCTrUkGnIt3-kNSSs54PHHGhmOjciNatzuMfPlvebNp9Gtz9kTfcJcClTnGHfuMWlztYeCfiptAy_dY0SDUTKoEd4KlGnlA0SGBfZZW83oFNrtjUErqj6IOEpho9bVkibTBqbz6b8NITImQ8xY6iGYLn5NHROM0S4e3VRyOgQ2uRWTZhG2XUNRdd0cEKKHTtbS5NOeAi4-OYZSyDzE0yHW44facLgdkoPO-NU" },
  ]);

  return (
    <Layout title="Building Staff" role="admin">
      <div className="p-4 lg:p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <UserCheck className="text-[#137fec] w-6 h-6" />
            <h1 className="text-xl font-extrabold tracking-tight">Staff Management</h1>
          </div>
        </div>
        <div className="pb-3">
          <div className="flex w-full items-stretch rounded-lg h-11 border border-[#137fec]/10 shadow-sm overflow-hidden bg-white dark:bg-slate-800">
            <div className="text-slate-400 flex items-center justify-center pl-4">
              <Search className="w-5 h-5" />
            </div>
            <input 
              className="flex w-full min-w-0 flex-1 resize-none overflow-hidden text-slate-900 dark:text-slate-100 focus:outline-0 focus:ring-0 border-none bg-transparent h-full placeholder:text-slate-400 px-4 pl-2 text-sm font-medium" 
              placeholder="Search by name or role..." 
            />
          </div>
        </div>

        <div className="space-y-3 xl:grid xl:grid-cols-2 xl:gap-4 xl:space-y-0">
          {staff.map((member) => (
            <motion.div 
              key={member.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col gap-3"
            >
              <div className="flex justify-between items-start">
                <div className="flex gap-3 items-center">
                  <div className="relative">
                    <img className="size-12 rounded-full bg-slate-100 object-cover" src={member.avatar} alt={member.name} />
                    <div className={`absolute bottom-0 right-0 size-3 rounded-full border-2 border-white dark:border-slate-900 ${member.status === 'On Duty' ? 'bg-emerald-500' : 'bg-slate-400'}`}></div>
                  </div>
                  <div>
                    <h3 className="font-bold text-sm">{member.name}</h3>
                    <div className="flex items-center gap-1.5 mt-0.5">
                      <BadgeCheck className="w-3 h-3 text-[#137fec]" />
                      <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">{member.role} • {member.shift} Shift</p>
                    </div>
                  </div>
                </div>
                <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${member.status === 'On Duty' ? 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400'}`}>
                  {member.status}
                </span>
              </div>
              
              <div className="grid grid-cols-2 gap-2 pt-2 border-t border-slate-50 dark:border-slate-800">
                <div className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <Mail className="w-3.5 h-3.5" />
                  <span className="text-[11px] font-medium truncate">{member.email}</span>
                </div>
                <div className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
                  <Phone className="w-3.5 h-3.5" />
                  <span className="text-[11px] font-medium">{member.phone}</span>
                </div>
              </div>

              <div className="flex items-center gap-2 pt-1 text-xs font-bold uppercase tracking-widest text-slate-400">
                <ShieldAlert className="h-3.5 w-3.5" />
                Directory item
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </Layout>
  );
}
