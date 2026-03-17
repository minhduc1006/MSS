import { LucideIcon, Plus, Edit, Trash, Eye, Search, Check, X, UserPlus, Calendar, Bell, Download, Upload, Activity, Monitor, FileText, Settings, ShieldCheck, ClipboardCheck } from "lucide-react";

interface Action {
  label: string;
  icon: LucideIcon;
  onClick: () => void;
  color?: string;
}

interface ActionGridProps {
  onAction: (action: string) => void;
  extraActions?: boolean;
  visibleActions?: string[];
}

export default function ActionGrid({ onAction, extraActions = false, visibleActions }: ActionGridProps) {
  const handleAction = (label: string) => {
    onAction(label);
  };

  const baseActions: Action[] = [
    { label: "Create", icon: Plus, onClick: () => handleAction("Create"), color: "bg-blue-500" },
    { label: "Update", icon: Edit, onClick: () => handleAction("Update"), color: "bg-indigo-500" },
    { label: "Delete", icon: Trash, onClick: () => handleAction("Delete"), color: "bg-red-500" },
    { label: "View", icon: Eye, onClick: () => handleAction("View"), color: "bg-slate-500" },
    { label: "Search", icon: Search, onClick: () => handleAction("Search"), color: "bg-slate-500" },
    { label: "Approve", icon: Check, onClick: () => handleAction("Approve"), color: "bg-emerald-500" },
    { label: "Reject", icon: X, onClick: () => handleAction("Reject"), color: "bg-rose-500" },
    { label: "Assign", icon: UserPlus, onClick: () => handleAction("Assign"), color: "bg-violet-500" },
    { label: "Schedule", icon: Calendar, onClick: () => handleAction("Schedule"), color: "bg-amber-500" },
    { label: "Notify", icon: Bell, onClick: () => handleAction("Notify"), color: "bg-orange-500" },
    { label: "Export", icon: Download, onClick: () => handleAction("Export"), color: "bg-slate-600" },
    { label: "Import", icon: Upload, onClick: () => handleAction("Import"), color: "bg-slate-600" },
    { label: "Track", icon: Activity, onClick: () => handleAction("Track"), color: "bg-cyan-500" },
    { label: "Monitor", icon: Monitor, onClick: () => handleAction("Monitor"), color: "bg-sky-500" },
    { label: "Generate", icon: FileText, onClick: () => handleAction("Generate"), color: "bg-teal-500" },
  ];

  const extraItems: Action[] = [
    { label: "Manage", icon: Settings, onClick: () => handleAction("Manage"), color: "bg-slate-700" },
    { label: "Configure", icon: ShieldCheck, onClick: () => handleAction("Configure"), color: "bg-slate-700" },
    { label: "Validate", icon: ClipboardCheck, onClick: () => handleAction("Validate"), color: "bg-slate-700" },
  ];

  const actions = extraActions ? [...baseActions, ...extraItems] : baseActions;
  const filteredActions = visibleActions?.length
    ? actions.filter((action) => visibleActions.includes(action.label))
    : actions;

  if (filteredActions.length === 0) {
    return null;
  }

  return (
    <div className="grid grid-cols-3 gap-3 p-4 sm:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6">
      {filteredActions.map((action) => (
        <button
          key={action.label}
          onClick={action.onClick}
          className="flex flex-col items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white p-3 shadow-sm transition-all hover:border-[#137fec] active:scale-95 dark:border-slate-800 dark:bg-slate-900 lg:min-h-28"
        >
          <div className={`p-2 rounded-lg ${action.color} text-white`}>
            <action.icon className="w-5 h-5" />
          </div>
          <span className="text-[10px] font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400">{action.label}</span>
        </button>
      ))}
    </div>
  );
}
