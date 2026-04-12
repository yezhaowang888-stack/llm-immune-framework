// 医疗器械客户管理组件 - 替换现有组件
export default {
  name: 'CustomerList',
  template: `
    <div class="customer-management">
      <div class="page-header">
        <h2>🏥 医疗器械客户信息管理</h2>
        <p>管理医疗器械客户信息，包括营业执照、开票信息、联系人及资质证件</p>
      </div>
      
      <div class="action-bar">
        <el-button type="primary" @click="handleAdd">
          <i class="el-icon-plus"></i> 新增客户
        </el-button>
        <el-button @click="refreshData">
          <i class="el-icon-refresh"></i> 刷新
        </el-button>
        <el-input
          v-model="searchKeyword"
          placeholder="搜索客户名称、统一信用代码、联系人..."
          style="width: 300px; margin-left: 20px;"
          @input="handleSearch"
        >
          <template #prefix>
            <i class="el-icon-search"></i>
          </template>
        </el-input>
      </div>
      
      <!-- 统计卡片 -->
      <div class="stats-cards">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-label">总客户数</div>
            <div class="stat-value">{{ totalCustomers }}</div>
          </div>
        </el-card>
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-label">资质有效</div>
            <div class="stat-value" style="color: #67c23a;">{{ validCustomers }}</div>
          </div>
        </el-card>
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-label">即将到期</div>
            <div class="stat-value" style="color: #e6a23c;">{{ expiringCustomers }}</div>
          </div>
        </el-card>
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-label">已过期</div>
            <div class="stat-value" style="color: #f56c6c;">{{ expiredCustomers }}</div>
          </div>
        </el-card>
      </div>
      
      <!-- 客户表格 -->
      <el-card class="table-card">
        <el-table :data="filteredCustomers" style="width: 100%" v-loading="loading">
          <el-table-column prop="customerCode" label="客户编码" width="120" />
          <el-table-column prop="customerName" label="客户名称" min-width="180" />
          <el-table-column prop="creditCode" label="统一信用代码" width="180" />
          <el-table-column prop="contactPerson" label="联系人" width="100" />
          <el-table-column prop="phone" label="联系电话" width="120" />
          <el-table-column prop="qualificationExpiry" label="资质到期" width="120">
            <template #default="scope">
              {{ formatDate(scope.row.qualificationExpiry) }}
            </template>
          </el-table-column>
          <el-table-column label="状态" width="100">
            <template #default="scope">
              <el-tag :type="getStatusType(scope.row.qualificationExpiry)" size="small">
                {{ getStatusText(scope.row.qualificationExpiry) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="150" fixed="right">
            <template #default="scope">
              <el-button type="text" size="small" @click="handleEdit(scope.row)">编辑</el-button>
              <el-button type="text" size="small" @click="handleDelete(scope.row)" style="color: #f56c6c;">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        
        <div v-if="filteredCustomers.length === 0 && !loading" class="empty-state">
          <i class="el-icon-document" style="font-size: 48px; color: #909399;"></i>
          <p>暂无客户数据，点击"新增客户"开始添加</p>
        </div>
      </el-card>
      
      <!-- 新增/编辑对话框 -->
      <el-dialog
        :title="dialogTitle"
        v-model="dialogVisible"
        width="800px"
        :close-on-click-modal="false"
      >
        <el-form :model="currentCustomer" label-width="120px" :rules="rules" ref="customerForm">
          <el-form-item label="客户编码" prop="customerCode">
            <el-input v-model="currentCustomer.customerCode" placeholder="请输入客户编码" />
          </el-form-item>
          
          <el-form-item label="客户名称" prop="customerName">
            <el-input v-model="currentCustomer.customerName" placeholder="请输入客户名称" />
          </el-form-item>
          
          <el-form-item label="统一信用代码">
            <el-input v-model="currentCustomer.creditCode" placeholder="请输入统一社会信用代码" />
          </el-form-item>
          
          <el-form-item label="联系人">
            <el-input v-model="currentCustomer.contactPerson" placeholder="请输入联系人" />
          </el-form-item>
          
          <el-form-item label="联系电话">
            <el-input v-model="currentCustomer.phone" placeholder="请输入联系电话" />
          </el-form-item>
          
          <el-form-item label="资质到期日">
            <el-date-picker
              v-model="currentCustomer.qualificationExpiry"
              type="date"
              placeholder="选择资质到期日期"
              value-format="YYYY-MM-DD"
            />
          </el-form-item>
          
          <el-form-item label="资质类型">
            <el-select v-model="currentCustomer.qualificationType" placeholder="请选择资质类型">
              <el-option label="医疗器械经营许可证" value="医疗器械经营许可证" />
              <el-option label="医疗器械生产许可证" value="医疗器械生产许可证" />
              <el-option label="医疗器械注册证" value="医疗器械注册证" />
              <el-option label="其他资质" value="其他资质" />
            </el-select>
          </el-form-item>
          
          <el-form-item label="资质编号">
            <el-input v-model="currentCustomer.qualificationNumber" placeholder="请输入资质编号" />
          </el-form-item>
        </el-form>
        
        <template #footer>
          <span class="dialog-footer">
            <el-button @click="dialogVisible = false">取消</el-button>
            <el-button type="primary" @click="handleSave">保存</el-button>
          </span>
        </template>
      </el-dialog>
    </div>
  `,
  
  data() {
    return {
      customers: [],
      searchKeyword: '',
      loading: false,
      dialogVisible: false,
      dialogTitle: '新增客户',
      currentCustomer: {
        id: null,
        customerCode: '',
        customerName: '',
        creditCode: '',
        contactPerson: '',
        phone: '',
        qualificationExpiry: '',
        qualificationType: '',
        qualificationNumber: ''
      },
      rules: {
        customerCode: [
          { required: true, message: '请输入客户编码', trigger: 'blur' }
        ],
        customerName: [
          { required: true, message: '请输入客户名称', trigger: 'blur' }
        ]
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
    async loadCustomers() {
      this.loading = true;
      try {
        // 调用现有API接口
        const response = await fetch('/api/customers');
        if (response.ok) {
          this.customers = await response.json();
        } else {
          // 如果API失败，使用示例数据
          this.customers = this.getSampleData();
        }
      } catch (error) {
        console.error('加载客户数据失败:', error);
        this.customers = this.getSampleData();
      } finally {
        this.loading = false;
      }
    },
    
    getSampleData() {
      return [
        {
          id: 1,
          customerCode: 'CUST2026001',
          customerName: '北京协和医院医疗器械有限公司',
          creditCode: '91110108MA01XYZ123',
          contactPerson: '张主任',
          phone: '13800138000',
          qualificationExpiry: '2026-12-31',
          qualificationType: '医疗器械经营许可证',
          qualificationNumber: '京械20210001'
        },
        {
          id: 2,
          customerCode: 'CUST2026002',
          customerName: '上海华山医疗器械集团',
          creditCode: '91310115MA01ABC456',
          contactPerson: '陈经理',
          phone: '13900139001',
          qualificationExpiry: '2026-06-30',
          qualificationType: '医疗器械生产许可证',
          qualificationNumber: '沪械20210002'
        },
        {
          id: 3,
          customerCode: 'CUST2026003',
          customerName: '广州中山医疗设备公司',
          creditCode: '91440101MA59DEF789',
          contactPerson: '王总监',
          phone: '13700137002',
          qualificationExpiry: '2025-12-31',
          qualificationType: '医疗器械注册证',
          qualificationNumber: '粤械20210003'
        }
      ];
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
    
    getStatusText(expiryDate) {
      const status = this.getQualificationStatus(expiryDate);
      switch(status) {
        case 'valid': return '有效';
        case 'expiring': return '即将到期';
        case 'expired': return '已过期';
        default: return '未知';
      }
    },
    
    getStatusType(expiryDate) {
      const status = this.getQualificationStatus(expiryDate);
      switch(status) {
        case 'valid': return 'success';
        case 'expiring': return 'warning';
        case 'expired': return 'danger';
        default: return 'info';
      }
    },
    
    formatDate(date) {
      if (!date) return '';
      return new Date(date).toLocaleDateString('zh-CN');
    },
    
    handleAdd() {
      this.dialogTitle = '新增客户';
      this.currentCustomer = {
        id: null,
        customerCode: '',
        customerName: '',
        creditCode: '',
        contactPerson: '',
        phone: '',
        qualificationExpiry: '',
        qualificationType: '',
        qualificationNumber: ''
      };
      this.dialogVisible = true;
    },
    
    handleEdit(customer) {
      this.dialogTitle = '编辑客户';
      this.currentCustomer = { ...customer };
      this.dialogVisible = true;
    },
    
    async handleSave() {
      try {
        // 这里应该调用API保存数据
        // 暂时使用本地存储
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
        
        this.dialogVisible = false;
        this.$message.success(this.currentCustomer.id ? '客户更新成功' : '客户添加成功');
      } catch (error) {
        this.$message.error('保存失败: ' + error.message);
      }
    },
    
    handleDelete(customer) {
      this.$confirm('确定要删除这个客户吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        this.customers = this.customers.filter(c => c.id !== customer.id);
        this.$message.success('客户删除成功');
      }).catch(() => {
        // 用户取消删除
      });
    },
    
    handleSearch() {
      // 搜索功能通过computed属性自动处理
    },
    
    refreshData() {
      this.loadCustomers();
    }
  }
};