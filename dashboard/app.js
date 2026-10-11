// AWS CloudOps & Cost Governance - Interactive Portal Engine (app.js)

let currentMode = 'simulation';
let ec2State = 'stopped';
let rdsState = 'stopped';
let cpuUtilization = 0.0;
let alarmActive = false;

// Initialize Lucide Icons & Chart on Load
document.addEventListener('DOMContentLoaded', () => {
  lucide.createIcons();
  initCostChart();
  updateUiState();
});

function logToConsole(message, type = 'info') {
  const consoleEl = document.getElementById('consoleLog');
  const p = document.createElement('p');
  const now = new Date().toLocaleTimeString('en-US', { hour12: false });

  if (type === 'cmd') {
    p.className = 'text-amber-400 font-semibold';
    p.textContent = `[${now}] $ ${message}`;
  } else if (type === 'success') {
    p.className = 'text-emerald-400';
    p.textContent = `[${now}] ${message}`;
  } else if (type === 'warn') {
    p.className = 'text-rose-400';
    p.textContent = `[${now}] [ALERT] ${message}`;
  } else {
    p.className = 'text-slate-300';
    p.textContent = `[${now}] ${message}`;
  }

  consoleEl.appendChild(p);
  consoleEl.scrollTop = consoleEl.scrollHeight;
}

function clearConsole() {
  const consoleEl = document.getElementById('consoleLog');
  consoleEl.innerHTML = '<p class="text-slate-500">[CONSOLE CLEARED] Telemetry ready.</p>';
}

function setMode(mode) {
  currentMode = mode;
  const btnSim = document.getElementById('btnModeSim');
  const btnLive = document.getElementById('btnModeLive');

  if (mode === 'simulation') {
    btnSim.className = 'px-3 py-1 rounded-md text-xs font-medium transition-all bg-amber-500 text-slate-950 shadow';
    btnLive.className = 'px-3 py-1 rounded-md text-xs font-medium text-slate-400 hover:text-white transition-all';
    logToConsole('Switched to Interactive Presentation Mode (Zero AWS spend).', 'info');
  } else {
    btnLive.className = 'px-3 py-1 rounded-md text-xs font-medium transition-all bg-amber-500 text-slate-950 shadow';
    btnSim.className = 'px-3 py-1 rounded-md text-xs font-medium text-slate-400 hover:text-white transition-all';
    logToConsole('Switched to Live AWS API Mode. Connecting to AWS ap-southeast-1...', 'cmd');
    setTimeout(() => {
      logToConsole('Live AWS API: In active production, invokes API Gateway or AWS Systems Manager directly.', 'info');
    }, 500);
  }
}

function triggerAction(action) {
  if (action === 'stop') {
    logToConsole("aws lambda invoke --function-name cloudops-governance-instance-scheduler --payload '{\"action\": \"stop\"}' response.json", "cmd");

    setTimeout(() => {
      ec2State = 'stopped';
      rdsState = 'stopped';
      cpuUtilization = 0.0;
      updateUiState();

      const payload = {
        statusCode: 200,
        body: {
          action: "stop",
          ec2: { stopped: ["i-00d94d51d86756658"] },
          rds: { "cloudops-governance-dev-db": "Stop initiated" }
        }
      };

      logToConsole(`HTTP 200 OK: ${JSON.stringify(payload)}`, "success");
      logToConsole("FinOps Routine Verified: Non-production compute halted for off-hours (saving 67% billable runtime).", "info");
    }, 400);

  } else if (action === 'start') {
    logToConsole("aws lambda invoke --function-name cloudops-governance-instance-scheduler --payload '{\"action\": \"start\"}' response.json", "cmd");

    setTimeout(() => {
      ec2State = 'running';
      rdsState = 'available';
      cpuUtilization = 14.2;
      updateUiState();

      const payload = {
        statusCode: 200,
        body: {
          action: "start",
          ec2: { started: ["i-00d94d51d86756658"] },
          rds: { "cloudops-governance-dev-db": "Start initiated" }
        }
      };

      logToConsole(`HTTP 200 OK: ${JSON.stringify(payload)}`, "success");
      logToConsole("Workload Resumed: Workloads ready for business hours (08:00 Bangkok).", "info");
    }, 400);
  }
}

function simulateCpuSpike() {
  logToConsole("Simulating high compute stress test on EC2 instance i-00d94d51d86756658...", "cmd");

  ec2State = 'running';
  cpuUtilization = 94.8;
  alarmActive = true;
  updateUiState();

  setTimeout(() => {
    logToConsole("CloudWatch Metric Alarm: CPUUtilization breached threshold (>80.0% for 2 consecutive periods)", "warn");
    logToConsole("Amazon SNS Notification published to topic 'cloudops-governance-incident-alerts' -> herren1809@gmail.com", "warn");
    document.getElementById('modalAlarm').classList.remove('hidden');
    lucide.createIcons();
  }, 600);
}

function dismissAlarm() {
  document.getElementById('modalAlarm').classList.add('hidden');
  alarmActive = false;
  cpuUtilization = ec2State === 'running' ? 12.5 : 0.0;
  updateUiState();
  logToConsole("CloudWatch Alarm acknowledged and cleared. State restored to OK.", "success");
}

function runAudit() {
  logToConsole("cd scripts && ./audit_finops_unused_resources.sh", "cmd");
  setTimeout(() => {
    logToConsole("==============================================================================", "info");
    logToConsole("  AWS FINOPS & GOVERNANCE AUDIT REPORT | Region: ap-southeast-1", "info");
    logToConsole("==============================================================================", "info");
    logToConsole("[*] Step 1: Scanning for Unattached EBS Volumes: [OK] Clean (0 found).", "success");
    if (ec2State === 'stopped') {
      logToConsole("[*] Step 2: Scanning for Stopped EC2 Instances: [WARN] 1 stopped instance detected (i-00d94d51d86756658).", "warn");
    } else {
      logToConsole("[*] Step 2: Scanning for Stopped EC2 Instances: [OK] Clean (0 stopped).", "success");
    }
    logToConsole("[*] Step 3: Auditing S3 Buckets for Missing Lifecycle Rules: [OK] Clean (All buckets protected).", "success");
    logToConsole("[*] Step 4: Auditing Security Groups for World-Open Management Ports (0.0.0.0/0): [OK] Clean (Port 22 closed).", "success");
    logToConsole("==============================================================================", "info");
  }, 300);
}

function updateUiState() {
  // EC2 Badge
  const badgeEc2 = document.getElementById('badgeEc2');
  if (ec2State === 'running') {
    badgeEc2.className = 'px-2.5 py-1 rounded-full text-xs font-semibold status-running';
    badgeEc2.textContent = 'RUNNING';
  } else {
    badgeEc2.className = 'px-2.5 py-1 rounded-full text-xs font-semibold status-stopped';
    badgeEc2.textContent = 'STOPPED';
  }

  // RDS Badge
  const badgeRds = document.getElementById('badgeRds');
  if (rdsState === 'available') {
    badgeRds.className = 'px-2.5 py-1 rounded-full text-xs font-semibold status-running';
    badgeRds.textContent = 'AVAILABLE';
  } else {
    badgeRds.className = 'px-2.5 py-1 rounded-full text-xs font-semibold status-stopped';
    badgeRds.textContent = 'STOPPED TEMPORARILY';
  }

  // CPU Gauge
  const textEc2Cpu = document.getElementById('textEc2Cpu');
  const barEc2Cpu = document.getElementById('barEc2Cpu');
  textEc2Cpu.textContent = `${cpuUtilization.toFixed(1)}%`;
  barEc2Cpu.style.width = `${Math.min(cpuUtilization, 100)}%`;

  if (cpuUtilization > 80) {
    barEc2Cpu.className = 'h-full bg-rose-500 rounded-full transition-all duration-500';
    textEc2Cpu.className = 'font-mono text-rose-400 font-semibold';
  } else {
    barEc2Cpu.className = 'h-full bg-emerald-500 rounded-full transition-all duration-500';
    textEc2Cpu.className = 'font-mono text-slate-200 font-semibold';
  }

  // Alarms
  const badgeAlarmStatus = document.getElementById('badgeAlarmStatus');
  const dotAlarmCpu = document.getElementById('dotAlarmCpu');
  const textAlarmCpu = document.getElementById('textAlarmCpu');

  if (alarmActive) {
    badgeAlarmStatus.className = 'px-2 py-0.5 rounded text-[11px] font-semibold status-alarm';
    badgeAlarmStatus.textContent = '1 ALARM ACTIVE';
    dotAlarmCpu.className = 'w-2 h-2 rounded-full bg-rose-500 animate-ping';
    textAlarmCpu.className = 'text-rose-400 font-semibold font-mono';
    textAlarmCpu.textContent = 'ALARM (>80%)';
  } else {
    badgeAlarmStatus.className = 'px-2 py-0.5 rounded text-[11px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20';
    badgeAlarmStatus.textContent = 'ALL SYSTEMS OK';
    dotAlarmCpu.className = 'w-2 h-2 rounded-full bg-emerald-400';
    textAlarmCpu.className = 'text-emerald-400 font-semibold font-mono';
    textAlarmCpu.textContent = 'OK (<80%)';
  }
}

// Chart.js Configuration
function initCostChart() {
  const ctx = document.getElementById('costChart').getContext('2d');
  
  new Chart(ctx, {
    type: 'bar',
    data: {
      labels: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      datasets: [
        {
          label: 'Unmanaged 24/7 Runtime (24h/day)',
          data: [24, 24, 24, 24, 24, 24, 24],
          backgroundColor: 'rgba(148, 163, 184, 0.25)',
          borderColor: 'rgba(148, 163, 184, 0.5)',
          borderWidth: 1,
          borderRadius: 6
        },
        {
          label: 'FinOps Governed Schedule (11h/day, 0h weekend)',
          data: [11, 11, 11, 11, 11, 0, 0],
          backgroundColor: 'rgba(34, 197, 94, 0.75)',
          borderColor: 'rgba(34, 197, 94, 1)',
          borderWidth: 1,
          borderRadius: 6
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          labels: {
            color: '#94a3b8',
            font: { family: 'Calibri, sans-serif', size: 11 }
          }
        },
        tooltip: {
          callbacks: {
            footer: (items) => {
              const diff = items[0].raw - items[1].raw;
              return `Savings: ${diff} hours/day (-${Math.round((diff/items[0].raw)*100)}%)`;
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          max: 28,
          title: {
            display: true,
            text: 'Compute Hours / Day',
            color: '#64748b'
          },
          grid: { color: 'rgba(51, 65, 85, 0.4)' },
          ticks: { color: '#94a3b8' }
        },
        x: {
          grid: { display: false },
          ticks: { color: '#94a3b8' }
        }
      }
    }
  });
}
