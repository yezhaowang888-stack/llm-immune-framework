// 医疗器械产品管理Vue组件
const ProductsComponent = {
  template: `
    <div class="products-container">
      <header class="products-header">
        <h1>🏥 医疗器械产品信息管理系统</h1>
        <p>管理医疗器械产品信息、库存、价格及资质证件</p>
      </header>
      
      <div class="stats-cards">
        <div class="stat-card">
          <div class="stat-label">总产品数</div>
          <div class="stat-value">{{ totalProducts }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">库存充足</div>
          <div class="stat-value" style="color: #10b981;">{{ instockProducts }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">库存预警</div>
          <div class="stat-value" style="color: #f59e0b;">{{ lowstockProducts }}</div>
        </div>
        <div class="stat-card">
          <div class="stat-label">缺货产品</div>
          <div class="stat-value" style="color: #ef4444;">{{ outstockProducts }}</div>
        </div>
      </div>
      
      <div class="toolbar">
        <button class="btn btn-primary" @click="showAddModal">➕ 新增产品</button>
        <button class="btn btn-success" @click="loadProducts">🔄 刷新</button>
        <button class="btn" style="background: #8b5cf6; color: white;" @click="exportData">📥 导出数据</button>
        <input type="text" class="search-box" placeholder="搜索产品名称、型号、注册证号..." v-model="searchKeyword" @input="searchProducts">
      </div>
      
      <div class="products-table">
        <table v-if="filteredProducts.length > 0">
          <thead>
            <tr>
              <th>产品编码</th>
              <th>产品名称</th>
              <th>型号</th>
              <th>注册证号</th>
              <th>库存数量</th>
              <th>库存状态</th>
              <th>销售单价</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="product in filteredProducts" :key="product.id">
              <td>{{ product.productCode || '' }}</td>
              <td>{{ product.productName || '' }}</td>
              <td>{{ product.productModel || '' }}</td>
              <td>{{ product.medicalLicense || '' }}</td>
              <td>{{ product.stockQuantity || 0 }} {{ product.unit || '' }}</td>
              <td :class="'status-' + getStockStatus(product.stockQuantity, product.minStock)">
                {{ getStockStatusText(getStockStatus(product.stockQuantity, product.minStock)) }}
              </td>
              <td>¥{{ product.salePrice ? product.salePrice.toFixed(2) : '0.00' }}</td>
              <td>
                <button @click="editProduct(product.id)" class="btn-edit">编辑</button>
                <button @click="deleteProduct(product.id)" class="btn-delete">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-else style="color: #95a5a6; text-align: center; padding: 40px;">
          暂无产品数据，点击"新增产品"开始添加
        </p>
      </div>
      
      <!-- 产品模态框 -->
      <div class="modal" :class="{ show: showModal }">
        <div class="modal-content">
          <h2>{{ modalTitle }}</h2>
          <form @submit.prevent="saveProduct">
            <input type="hidden" v-model="currentProduct.id">
            
            <!-- 产品基本信息 -->
            <div class="form-section">
              <h3>📋 产品基本信息</h3>
              <div class="form-row">
                <div class="form-group">
                  <label>产品编码 <span style="color: red;">*</span></label>
                  <input type="text" v-model="currentProduct.productCode" required>
                </div>
                <div class="form-group">
                  <label>产品名称 <span style="color: red;">*</span></label>
                  <input type="text" v-model="currentProduct.productName" required>
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>产品型号</label>
                  <input type="text" v-model="currentProduct.productModel">
                </div>
                <div class="form-group">
                  <label>产品规格</label>
                  <input type="text" v-model="currentProduct.productSpec">
                </div>
              </div>
            </div>
            
            <!-- 医疗器械属性 -->
            <div class="form-section">
              <h3>🏥 医疗器械属性</h3>
              <div class="form-row">
                <div class="form-group">
                  <label>医疗器械注册证号</label>
                  <input type="text" v-model="currentProduct.medicalLicense">
                </div>
                <div class="form-group">
                  <label>生产许可证号</label>
                  <input type="text" v-model="currentProduct.productionLicense">
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>医疗器械分类</label>
                  <select v-model="currentProduct.medicalCategory">
                    <option value="">请选择</option>
                    <option value="一类">一类医疗器械</option>
                    <option value="二类">二类医疗器械</option>
                    <option value="三类">三类医疗器械</option>
                  </select>
                </div>
                <div class="form-group">
                  <label>注册证有效期</label>
                  <input type="date" v-model="currentProduct.licenseExpiry">
                </div>
              </div>
            </div>
            
            <!-- 库存管理 -->
            <div class="form-section">
              <h3>📦 库存管理</h3>
              <div class="form-row">
                <div class="form-group">
                  <label>当前库存数量</label>
                  <input type="number" v-model.number="currentProduct.stockQuantity" min="0">
                </div>
                <div class="form-group">
                  <label>计量单位</label>
                  <input type="text" v-model="currentProduct.unit" value="个">
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>最低库存预警</label>
                  <input type="number" v-model.number="currentProduct.minStock" min="0" value="10">
                </div>
                <div class="form-group">
                  <label>存储条件</label>
                  <input type="text" v-model="currentProduct.storageCondition" value="常温">
                </div>
              </div>
            </div>
            
            <!-- 价格信息 -->
            <div class="form-section">
              <h3>💰 价格信息</h3>
              <div class="form-row">
                <div class="form-group">
                  <label>采购单价（元）</label>
                  <input type="number" v-model.number="currentProduct.purchasePrice" min="0" step="0.01">
                </div>
                <div class="form-group">
                  <label>销售单价（元）</label>
                  <input type="number" v-model.number="currentProduct.salePrice" min="0" step="0.01">
                </div>
              </div>
              
              <div class="form-row">
                <div class="form-group">
                  <label>供应商</label>
                  <input type="text" v-model="currentProduct.supplier">
                </div>
                <div class="form-group">
                  <label>产品批号</label>
                  <input type="text" v-model="currentProduct.batchNumber">
                </div>
              </div>
            </div>
            
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">保存产品</button>
              <button type="button" class="btn btn-cancel" @click="hideModal">取消</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  `,
  
  data() {
    return {
      products: [],
      searchKeyword: '',
      showModal: false,
      modalTitle: '新增产品',
      currentProduct: {
        id: null,
        productCode: '',
        productName: '',
        productModel: '',
        productSpec: '',
        medicalLicense: '',
        productionLicense: '',
        medicalCategory: '',
        licenseExpiry: '',
        stockQuantity: 0,
        unit: '个',
        minStock: 10,
        storageCondition: '常温',
        purchasePrice: 0,
        salePrice: 0,
        supplier: '',
        batchNumber: ''
      }
    };
  },
  
  computed: {
    totalProducts() {
      return this.products.length;
    },
    
    instockProducts() {
      return this.products.filter(p => this.getStockStatus(p.stockQuantity, p.minStock) === 'instock').length;
    },
    
    lowstockProducts() {
      return this.products.filter(p => this.getStockStatus(p.stockQuantity, p.minStock) === 'lowstock').length;
    },
    
    outstockProducts() {
      return this.products.filter(p => this.getStockStatus(p.stockQuantity, p.minStock) === 'outstock').length;
    },
    
    filteredProducts() {
      if (!this.searchKeyword) return this.products;
      const keyword = this.searchKeyword.toLowerCase();
      return this.products.filter(product => 
        (product.productName && product.productName.toLowerCase().includes(keyword)) ||
        (product.productCode && product.productCode.toLowerCase().includes(keyword)) ||
        (product.productModel && product.productModel.toLowerCase().includes(keyword)) ||
        (product.medicalLicense && product.medicalLicense.toLowerCase().includes(keyword)) ||
        (product.supplier && product.supplier.toLowerCase().includes(keyword))
      );
    }
  },
  
  mounted() {
    this.loadProducts();
  },
  
  methods: {
    loadProducts() {
      // 从localStorage加载数据
      const storedData = localStorage.getItem('medical_products_vue');
      if (storedData) {
        this.products = JSON.parse(storedData);
      } else {
        // 初始化示例数据
        this.products = [
          {
            id: 1,
            productCode: 'PROD2026001',
            productName: '一次性使用无菌注射器',
            productModel: '5ml',
            productSpec: '带针',
            medicalLicense: '国械注准20213456789',
            productionLicense: '苏食药监械生产许20210001',
            medicalCategory: '三类',
            licenseExpiry: '2026-12-31',
            stockQuantity: 150,
            unit: '支',
            minStock: 50,
            storageCondition: '常温干燥',
            purchasePrice: 1.20,
            salePrice: 2.50,
            supplier: '江苏医疗器械有限公司',
            batchNumber: '20260401'
          },
          {
            id: 2,
            productCode: 'PROD2026002',
            productName: '医用外科口罩',
            productModel: '三层',
            productSpec: '耳挂式',
            medicalLicense: '国械注准20212345678',
            productionLicense: '沪食药监械生产许20210002',
            medicalCategory: '二类',
            licenseExpiry: '2026-06-30',
            stockQuantity: 25,
            unit: '盒',
            minStock: 30,
            storageCondition: '常温',
            purchasePrice: 8.50,
            salePrice: 15.00,
            supplier: '上海医疗用品厂',
            batchNumber: '20260315'
          },
          {
            id: 3,
            productCode: 'PROD2026003',
            productName: '电子体温计',
            productModel: 'DT-01',
            productSpec: '额温枪',
            medicalLicense: '国械注准20211234567',
            productionLicense: '粤食药监械生产许20210003',
            medicalCategory: '二类',
            licenseExpiry: '2027-03-31',
            stockQuantity: 0,
            unit: '个',
            minStock: 10,
            storageCondition: '常温防潮',
            purchasePrice: 45.00,
            salePrice: 89.00,
            supplier: '广东医疗设备公司',
            batchNumber: '20260228'
          }
        ];
        this.saveProducts();
      }
    },
    
    saveProducts() {
      localStorage.setItem('medical_products_vue', JSON.stringify(this.products));
    },
    
    getStockStatus(quantity, minStock) {
      if (quantity === 0) return 'outstock';
      if (quantity < minStock) return 'lowstock';
      return 'instock';
    },
    
    getStockStatusText(status) {
      switch(status) {
        case 'instock': return '库存充足';
        case 'lowstock': return '库存预警';
        case 'outstock': return '缺货';
        default: return '未知';
      }
    },
    
    showAddModal() {
      this.modalTitle = '新增产品';
      this.currentProduct = {
        id: null,
        productCode: '',
        productName: '',
        productModel: '',
        productSpec: '',
        medicalLicense: '',
        productionLicense: '',
        medicalCategory: '',
        licenseExpiry: '',
        stockQuantity: 0,
        unit: '个',
        minStock: 10,
        storageCondition: '常温',
        purchasePrice: 0,
        salePrice: 0,
        supplier: '',
        batchNumber: ''
      };
      this.showModal = true;
    },
    
    editProduct(id) {
      const product = this.products.find(p => p.id === id);
      if (product) {
        this.modalTitle = '编辑产品';
        this.currentProduct = { ...product };
        this.showModal = true;
      }
    },
    
    saveProduct() {
      if (this.currentProduct.id) {
        // 更新
        const index = this.products.findIndex(p => p.id === this.currentProduct.id);
        if (index !== -1) {
          this.products[index] = { ...this.currentProduct };
        }
      } else {
        // 新增
        this.currentProduct.id = this.products.length > 0 
          ? Math.max(...this.products.map(p => p.id)) + 1 
          : 1;
        this.products.push({ ...this.currentProduct });
      }
      
      this.saveProducts();
      this.hideModal();
      alert(this.currentProduct.id ? '产品更新成功' : '产品添加成功');
    },
    
    deleteProduct(id) {
      if (!confirm('确定要删除这个产品吗？')) return;
      
      this.products = this.products.filter(p => p.id !== id);
      this.saveProducts();
      alert('产品删除成功');
    },
    
    hideModal() {
      this.showModal = false;
    },
    
    searchProducts() {
      // 搜索功能通过computed属性自动处理
    },
    
    exportData() {
      const dataStr = JSON.stringify(this.products, null, 2);
      const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
      const exportFileDefaultName = '产品数据_' + new Date().toISOString().split('T')[0] + '.json';
      
      const linkElement = document.createElement('a');
      linkElement.setAttribute('href', dataUri);
      linkElement.setAttribute('download', exportFileDefaultName);
      linkElement.click();
    }
  }
};

// 导出组件
export default ProductsComponent;