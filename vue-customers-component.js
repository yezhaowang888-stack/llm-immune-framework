// 医疗器械客户管理Vue组件
const CustomersComponent = {
  template: `
    <div class="customers-container">
      <header class="customers-header">
        <h1>🏥 医疗器械客户全信息管理系统</h1>
        <p>完整管理客户营业执照、开票信息、联系人、授权人及各类资质证件</p>
      </header>
      
      <div class="stats-cards">
        <div class="stat-card">
          <div class="stat-label">总客户数</div>
          <div class="stat-value">{{ totalCustomers }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">资质有效</div>
          <div class="stat-value" style="color: #10b981;">{{ validCustomers }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">即将到期</div>
          <div class="stat-value" style="color: #f59e0b;">{{ expiringCustomers }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">已过期</div>
          <div class="stat-value" style="color: #ef4444;">{{ expiredCustomers }}</div>
        </div>
      </div>
      
      <div class="toolbar">
        <button class="btn btn-primary" @click="showAddModal">➕ 新增客户</button>
        <button class="btn btn-success" @click="loadCustomers">🔄 刷新</button>
        <button class="btn" style="background: #8b5cf6; color: white;" @click="exportData">📥 导出数据</button>
        <input type="text" class="search-box" placeholder="搜索客户名称、统一信用代码、联系人..." v-model="searchKeyword" @input="searchCustomers">
      </div>
      
      <div class="customers-table">
        <table v-if="filteredCustomers.length > 0">
          <thead>
            <tr>
              <th>客户编码</th>
              <th>客户名称</th>
              <th>统一信用代码</th>
              <th>联系人</th>
              <th>联系电话</th>
              <th>资质到期</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="customer in filteredCustomers" :key="customer.id">
              <td>{{ customer.customerCode || '' }}</td>
              <td>{{ customer.customerName || '' }}</td>
              <td>{{ customer.creditCode || '' }}</td>
              <td>{{ customer.contactPerson || '' }}</td>
              <td>{{ customer.contactPhone || '' }}</td>
              <td>{{ customer.qualificationExpiry || '' }}</td>
              <td :class="'status-' + getQualificationStatus(customer.qualificationExpiry)">
                {{ getStatusText(getQualificationStatus(customer.qualificationExpiry)) }}
              </td>
              <td>
                <button @click="editCustomer(customer.id)" class="btn-edit">编辑</button>
                <button @click="deleteCustomer(customer.id)" class="btn-delete">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else style="color: #95a5a6; text-align: center; padding: 40px;">
          暂无客户数据，点击"新增客户"开始添加
        </p>
      </div>
      
      <!-- 模态框 -->
      <div class="modal" :class="{ show: showModal }">
        <div class="modal-content">
          <h2>{{ modalTitle }}</h2>
          <form @submit.prevent="saveCustomer">
            <input type="hidden" v-model="currentCustomer.id">
            
            <div class="form-row">
              <div class="form-group">
                <label>客户编码 <span style="color: red;">*</span></label>
                <input type="text" v-model="currentCustomer.customerCode" required>
              </div>
              <div class="form-group">
                <label>客户名称 <span style="color: red;">*</span></label>
                <input type="text" v-model="currentCustomer.customerName" required>
              </div>
            </div>
            
            <div class="form-row">
              <div class="form-group">
                <label>统一信用代码</label>
                <input type="text" v-model="currentCustomer.creditCode">
              </div>
              <div class="form-group">
                <label>联系人</label>
                <input type="text" v-model="currentCustomer.contactPerson">
              </div>
            </div>
            
            <div class="form-row">
              <div class="form-group">
                <label>联系电话</label>
                <input type="tel" v-model="currentCustomer.contactPhone">
              </div>
              <div class="form-group">
                <label>资质到期日</label>
                <input type="date" v-model="currentCustomer.qualificationExpiry">
              </div>
            </div>
            
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">保存</button>
              <button type="button" class="btn btn-cancel" @click="hideModal">取消</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  `,
  
  data() {
    return {
      customers: [],
      searchKeyword: '',
      showModal: false,
      modalTitle: '新增客户',
      currentCustomer: {
        id: null,
        customerCode: '',
        customerName: '',
        creditCode: '',
        contactPerson: '',
        contactPhone: '',
        qualificationExpiry: ''
      }
    };
  },
  
  computed: {
    totalCustomers() {
      return this.customers.length;
    },
    
    validCustomers() {
      return this.customers.filter(c => this.getQualificationStatus(c.qualificationExpiry) === 'valid').length;
    },
    
    expiringCustomers() {
      return this.customers.filter(c => this.getQualificationStatus(c.qualificationExpiry) === 'expiring').length;
    },
    
    expiredCustomers() {
      return this.customers.filter(c => this.getQualificationStatus(c.qualificationExpiry) === 'expired').length;
    },
    
    filteredCustomers() {
      if (!this.searchKeyword) return this.customers;
      const keyword = this.searchKeyword.toLowerCase();
      return this.customers.filter(customer => 
        (customer.customerName && customer.customerName.toLowerCase().includes(keyword)) ||
        (customer.customerCode && customer.customerCode.toLowerCase().includes(keyword)) ||
        (customer.creditCode && customer.creditCode.toLowerCase().includes(keyword)) ||
        (customer.contactPerson && customer.contactPerson.toLowerCase().includes(keyword))
      );
    }
  },
  
  mounted() {
    this.loadCustomers();
  },
  
  methods: {
    loadCustomers() {
      // 从localStorage加载数据
      const storedData = localStorage.getItem('medical_customers_vue');
      if (storedData) {
        this.customers = JSON.parse(storedData);
      } else {
        // 初始化示例数据
        this.customers = [
          {
            id: 1,
            customerCode: 'CUST2026001',
            customerName: '北京协和医院医疗器械有限公司',
            creditCode: '91110108MA01XYZ123',
            contactPerson: '张主任',
            contactPhone: '13800138000',
            qualificationExpiry: '2026-12-31'
          },
          {
            id: 2,
            customerCode: 'CUST2026002',
            customerName: '上海华山医疗器械集团',
            creditCode: '91310115MA01ABC456',
            contactPerson: '陈经理',
            contactPhone: '13900139001',
            qualificationExpiry: '2026-06-30'
          },
          {
            id: 3,
            customerCode: 'CUST2026003',
            customerName: '广州中山医疗设备公司',
            creditCode: '91440101MA59DEF789',
            contactPerson: '王总监',
            contactPhone: '13700137002',
            qualificationExpiry: '2025-12-31'
          }
        ];
        this.saveCustomers();
      }
    },
    
    saveCustomers() {
      localStorage.setItem('medical_customers_vue', JSON.stringify(this.customers));
    },
    
    getQualificationStatus(expiryDate) {
      if (!expiryDate) return 'unknown';
      const expiry = new Date(expiryDate);
      const today = new Date();
      const daysDiff = Math.ceil((expiry - today) / (1000 * 60 * 60 * 24));
      
      if (daysDiff < 0) return 'expired';
      if (daysDiff <= 30) return 'expiring';
      return 'valid';
    },
    
    getStatusText(status) {
      switch(status) {
        case 'valid': return '有效';
        case 'expiring': return '即将到期';
        case 'expired': return '已过期';
        default: return '未知';
      }
    },
    
    showAddModal() {
      this.modalTitle = '新增客户';
      this.currentCustomer = {
        id: null,
        customerCode: '',
        customerName: '',
        creditCode: '',
        contactPerson: '',
        contactPhone: '',
        qualificationExpiry: ''
      };
      this.showModal = true;
    },
    
    editCustomer(id) {
      const customer = this.customers.find(c => c.id === id);
      if (customer) {
        this.modalTitle = '编辑客户';
        this.currentCustomer = { ...customer };
        this.showModal = true;
      }
    },
    
    saveCustomer() {
      if (this.currentCustomer.id) {
        // 更新
        const index = this.customers.findIndex(c => c.id === this.currentCustomer.id);
        if (index !== -1) {
          this.customers[index] = { ...this.currentCustomer };
        }
      } else {
        // 新增
        this.currentCustomer.id = this.customers.length > 0 
          ? Math.max(...this.customers.map(c => c.id)) + 1 
          : 1;
        this.customers.push({ ...this.currentCustomer });
      }
      
      this.saveCustomers();
      this.hideModal();
      alert(this.currentCustomer.id ? '客户更新成功' : '客户添加成功');
    },
    
    deleteCustomer(id) {
      if (!confirm('确定要删除这个客户吗？')) return;
      
      this.customers = this.customers.filter(c => c.id !== id);
      this.saveCustomers();
      alert('客户删除成功');
    },
    
    hideModal() {
      this.showModal = false;
    },
    
    searchCustomers() {
      // 搜索功能通过computed属性自动处理
    },
    
    exportData() {
      const dataStr = JSON.stringify(this.customers, null, 2);
      const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
      const exportFileDefaultName = '客户数据_' + new Date().toISOString().split('T')[0] + '.json';
      
      const linkElement = document.createElement('a');
      linkElement.setAttribute('href', dataUri);
      linkElement.setAttribute('download', exportFileDefaultName);
      linkElement.click();
    }
  }
};

// 导出组件
export default CustomersComponent;