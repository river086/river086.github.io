/**
 * PSP Dashboard System for SimLifeGame
 * Handles the Personal Software Process tracking interface
 */

class PSPDashboard {
  constructor(gameState) {
    this.gameState = gameState;
    this.isVisible = false;
    this.init();
  }

  init() {
    // Only initialize if player is PSP Software Developer
    if (this.gameState.player.professionId === 'software_developer_psp') {
      this.createButton();
      this.createModal();
      this.bindEvents();
    }
  }

  createButton() {
    const button = document.createElement('button');
    button.className = 'psp-dashboard-btn';
    button.textContent = 'PSP Dashboard';
    button.addEventListener('click', () => this.show());
    
    // Insert button next to portfolio button
    const gameUI = document.querySelector('.game-ui-header');
    if (gameUI) {
      gameUI.appendChild(button);
    }
  }

  createModal() {
    // Create backdrop
    this.backdrop = document.createElement('div');
    this.backdrop.className = 'psp-modal-backdrop hidden';
    this.backdrop.addEventListener('click', () => this.hide());

    // Create modal
    this.modal = document.createElement('div');
    this.modal.className = 'psp-dashboard-modal hidden';
    this.modal.innerHTML = this.getModalHTML();

    document.body.appendChild(this.backdrop);
    document.body.appendChild(this.modal);
  }

  getModalHTML() {
    const psp = this.gameState.player.pspSystem || this.getDefaultPSPState();
    
    return `
      <div class="header">
        <h2>Personal Software Process Dashboard</h2>
        <span class="close-btn">&times;</span>
      </div>
      
      <div class="stats-grid">
        <div class="stat-card productivity">
          <h3>Productivity Score</h3>
          <div class="score">${psp.productivityScore}/100</div>
          <div class="trend">↗ +${this.getProductivityTrend()} this month</div>
        </div>
        
        <div class="stat-card quality">
          <h3>Quality Score</h3>
          <div class="score">${psp.qualityScore}/100</div>
          <div class="defect-rate">${psp.defectRate.toFixed(1)} defects/1000 LOC</div>
        </div>
        
        <div class="stat-card projects">
          <h3>Projects</h3>
          <div class="count">${psp.completedProjects}/${psp.totalProjects}</div>
          <div class="success-rate">${this.getSuccessRate()}% success rate</div>
        </div>
        
        <div class="stat-card income">
          <h3>Consulting Income</h3>
          <div class="amount">$${psp.consultingIncome.toLocaleString()}/month</div>
          <div class="next-opportunity">Next: ${this.getDaysUntilConsulting()} days</div>
        </div>
      </div>
      
      <div class="actions-panel">
        <button class="psp-btn create-project" data-action="createProject">New Project</button>
        <button class="psp-btn add-task" data-action="addTask">Add Task</button>
        <button class="psp-btn record-time" data-action="recordTime">Record Time</button>
        <button class="psp-btn view-reports" data-action="viewReports">View Reports</button>
      </div>
      
      <div class="recent-activity">
        <h4>Recent Activity</h4>
        <ul class="activity-log">
          ${this.getRecentActivity()}
        </ul>
      </div>
    `;
  }

  bindEvents() {
    // Close button event (will be bound after modal is shown)
    document.addEventListener('click', (e) => {
      if (e.target.classList.contains('close-btn')) {
        this.hide();
      }
      
      // PSP action buttons
      if (e.target.dataset.action) {
        this.handleAction(e.target.dataset.action);
      }
    });

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.isVisible) {
        this.hide();
      }
    });
  }

  show() {
    this.updateContent();
    this.backdrop.classList.remove('hidden');
    this.modal.classList.remove('hidden');
    this.isVisible = true;
    
    // Focus management for accessibility
    const closeBtn = this.modal.querySelector('.close-btn');
    if (closeBtn) closeBtn.focus();
  }

  hide() {
    this.backdrop.classList.add('hidden');
    this.modal.classList.add('hidden');
    this.isVisible = false;
  }

  updateContent() {
    if (this.modal) {
      this.modal.innerHTML = this.getModalHTML();
    }
  }

  handleAction(action) {
    switch (action) {
      case 'createProject':
        this.createProject();
        break;
      case 'addTask':
        this.addTask();
        break;
      case 'recordTime':
        this.recordTime();
        break;
      case 'viewReports':
        this.viewReports();
        break;
    }
  }

  createProject() {
    const projectName = prompt('Enter project name:');
    if (projectName) {
      this.gameState.executePSPCommand(`psp project create "${projectName}"`);
      this.updateContent();
      this.showNotification(`Project "${projectName}" created!`);
    }
  }

  addTask() {
    const taskTitle = prompt('Enter task title:');
    const estimatedHours = prompt('Estimated hours:');
    if (taskTitle && estimatedHours) {
      this.gameState.executePSPCommand(`psp task add "${taskTitle}" ${estimatedHours}h`);
      this.updateContent();
      this.showNotification(`Task "${taskTitle}" added!`);
    }
  }

  recordTime() {
    const hours = prompt('Hours worked:');
    if (hours) {
      this.gameState.executePSPCommand(`psp metric record time ${hours}h`);
      this.updateContent();
      this.showNotification(`${hours} hours recorded!`);
    }
  }

  viewReports() {
    // This would open a separate reports interface
    alert('Reports feature coming soon! Use console commands for now:\n- psp report productivity\n- psp report quality');
  }

  getDefaultPSPState() {
    return {
      enabled: true,
      totalProjects: 0,
      completedProjects: 0,
      totalTasks: 0,
      completedTasks: 0,
      totalHoursTracked: 0,
      productivityScore: 50,
      qualityScore: 50,
      defectRate: 15.0,
      consultingIncome: 0,
      lastConsultingMonth: 0
    };
  }

  getProductivityTrend() {
    // Simulate productivity trend calculation
    const psp = this.gameState.player.pspSystem;
    if (!psp || psp.totalHoursTracked < 20) return 0;
    return Math.floor(Math.random() * 10) + 1;
  }

  getSuccessRate() {
    const psp = this.gameState.player.pspSystem;
    if (!psp || psp.totalProjects === 0) return 85;
    return Math.floor((psp.completedProjects / psp.totalProjects) * 100);
  }

  getDaysUntilConsulting() {
    const psp = this.gameState.player.pspSystem;
    if (!psp) return 30;
    
    // Calculate days until next consulting opportunity
    const currentMonth = this.gameState.currentMonth;
    const monthsSinceLastConsulting = currentMonth - psp.lastConsultingMonth;
    const cooldownMonths = 6; // From events spec
    
    if (monthsSinceLastConsulting >= cooldownMonths) {
      return Math.floor(Math.random() * 15) + 1; // 1-15 days
    } else {
      const remainingMonths = cooldownMonths - monthsSinceLastConsulting;
      return remainingMonths * 30 + Math.floor(Math.random() * 30);
    }
  }

  getRecentActivity() {
    const activities = [
      '✅ Completed task: User Authentication (8h)',
      '📊 Recorded 6.5h development time',
      '🐛 Fixed 2 defects in E-commerce project',
      '💰 Earned $1,200 from consulting',
      '📈 Productivity score increased to 85',
      '🎯 Completed project milestone',
      '📝 Updated PSP metrics database',
      '🔧 Optimized development process'
    ];
    
    // Return 4 random activities
    const selectedActivities = activities
      .sort(() => 0.5 - Math.random())
      .slice(0, 4);
    
    return selectedActivities
      .map(activity => `<li>${activity}</li>`)
      .join('');
  }

  showNotification(message) {
    // Simple notification system
    const notification = document.createElement('div');
    notification.className = 'psp-notification';
    notification.textContent = message;
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: #4CAF50;
      color: white;
      padding: 15px;
      border-radius: 5px;
      z-index: 10000;
      animation: slideInRight 0.3s ease-out;
    `;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
      notification.remove();
    }, 3000);
  }

  // Update PSP metrics based on game actions
  updateMetrics(action, data) {
    if (!this.gameState.player.pspSystem) return;
    
    const psp = this.gameState.player.pspSystem;
    
    switch (action) {
      case 'projectCreated':
        psp.totalProjects++;
        break;
      case 'projectCompleted':
        psp.completedProjects++;
        psp.productivityScore = Math.min(100, psp.productivityScore + 2);
        break;
      case 'taskCompleted':
        psp.completedTasks++;
        psp.qualityScore = Math.min(100, psp.qualityScore + 1);
        break;
      case 'timeRecorded':
        psp.totalHoursTracked += data.hours;
        psp.productivityScore = Math.min(100, psp.productivityScore + 0.5);
        break;
      case 'defectFound':
        psp.defectRate = (psp.defectRate + data.defects) / 2;
        psp.qualityScore = Math.max(0, psp.qualityScore - 1);
        break;
    }
  }
}

// Export for use in main game
window.PSPDashboard = PSPDashboard;

// CSS injection for notifications animation
const style = document.createElement('style');
style.textContent = `
  @keyframes slideInRight {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }
  
  .psp-notification {
    animation: slideInRight 0.3s ease-out;
  }
`;
document.head.appendChild(style);