<template>
  <div class="product-management">
    <div class="header">
      <h2>产品管理</h2>
      <div class="header-actions">
        <el-button type="primary" @click="showAddDialog = true">新增产品</el-button>
        <el-button @click="refreshData">刷新</el-button>
      </div>
    </div>
    
    <!-- 搜索区域 -->
    <div class="search-area">
      <el-form :inline="true" :model="searchForm">
        <el-form-item label="产品名称">
          <el-input v-model="searchForm.name" placeholder="请输入产品名称" clearable />
        </el-form-item>
        <el-form-item label="产品类别">
          <el-select v-model="searchForm.category" placeholder="请选择产品类别" clearable>
            <el-option label="诊断设备" value="diagnostic" />
            <el-option label="治疗设备" value="therapeutic" />
            <el-option label="监护设备" value="monitoring" />
            <el-option label="手术器械" value="surgical" />
            <el-option label="耗材" value="consumable" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="resetSearch">重置</el-button>
        </el-form-item>
      </el-form>
    </div>
    
    <!-- 数据表格 -->
    <div class="table-area">
      <el-table :data="productList" border stripe style="width: 100%" v-loading="loading">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="产品名称" min-width="150" />
        <el-table-column prop="code" label="产品编码" width="120" />
        <el-table-column prop="category" label="产品类别" width="120">
          <template #default="{ row }">
            <el-tag :type="getCategoryTag(row.category)">{{ getCategoryText(row.category) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="specification" label="规格型号" width="150" />
        <el-table-column prop="unit" label="单位" width="80" />
        <el-table-column prop="price" label="单价(元)" width="120">
          <template #default="{ row }">
            {{ formatPrice(row.price) }}
          </template>
        </el-table-column>
        <el-table-column prop="stock" label="库存数量" width="100">
          <template #default="{ row }">
            <span :class="{ 'low-stock': row.stock < row.minStock }">
              {{ row.stock }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="minStock" label="最低库存" width="100" />
        <el-table-column prop="supplier" label="供应商" width="150" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'danger'">
              {{ row.status === 'active' ? '在售' : '停售' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" size="small" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </div>
    
    <!-- 新增/编辑对话框 -->
    <el-dialog v-model="showAddDialog" :title="dialogTitle" width="600px">
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="100px">
        <el-form-item label="产品名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入产品名称" />
        </el-form-item>
        <el-form-item label="产品编码" prop="code">
          <el-input v-model="formData.code" placeholder="请输入产品编码" />
        </el-form-item>
        <el-form-item label="产品类别" prop="category">
          <el-select v-model="formData.category" placeholder="请选择产品类别">
            <el-option label="诊断设备" value="diagnostic" />
            <el-option label="治疗设备" value="therapeutic" />
            <el-option label="监护设备" value="monitoring" />
            <el-option label="手术器械" value="surgical" />
            <el-option label="耗材" value="consumable" />
          </el-select>
        </el-form-item>
        <el-form-item label="规格型号" prop="specification">
          <el-input v-model="formData.specification" placeholder="请输入规格型号" />
        </el-form-item>
        <el-form-item label="单位" prop="unit">
          <el-input v-model="formData.unit" placeholder="请输入单位" />
        </el-form-item>
        <el-form-item label="单价(元)" prop="price">
          <el-input-number v-model="formData.price" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="库存数量" prop="stock">
          <el-input-number v-model="formData.stock" :min="0" />
        </el-form-item>
        <el-form-item label="最低库存" prop="minStock">
          <el-input-number v-model="formData.minStock" :min="0" />
        </el-form-item>
        <el-form-item label="供应商" prop="supplier">
          <el-input v-model="formData.supplier" placeholder="请输入供应商" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status">
            <el-radio label="active">在售</el-radio>
            <el-radio label="inactive">停售</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showAddDialog = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

// 数据
const loading = ref(false)
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const showAddDialog = ref(false)
const dialogTitle = ref('新增产品')
const formRef = ref(null)

// 搜索表单
const searchForm = reactive({
  name: '',
  category: ''
})

// 表单数据
const formData = reactive({
  id: '',
  name: '',
  code: '',
  category: 'diagnostic',
  specification: '',
  unit: '个',
  price: 0,
  stock: 0,
  minStock: 10,
  supplier: '',
  status: 'active'
})

// 验证规则
const rules = {
  name: [{ required: true, message: '请输入产品名称', trigger: 'blur' }],
  code: [{ required: true, message: '请输入产品编码', trigger: 'blur' }],
  category: [{ required: true, message: '请选择产品类别', trigger: 'change' }],
  price: [{ required: true, message: '请输入单价', trigger: 'blur' }]
}

// 产品列表数据
const productList = ref([
  {
    id: 1,
    name: '心电图机',
    code: 'ECG-001',
    category: 'diagnostic',
    specification: '12导联',
    unit: '台',
    price: 15000,
    stock: 25,
    minStock: 5,
    supplier: '迈瑞医疗',
    status: 'active'
  },
  {
    id: 2,
    name: '监护仪',
    code: 'MON-001',
    category: 'monitoring',
    specification: '多参数',
    unit: '台',
    price: 28000,
    stock: 18,
    minStock: 3,
    supplier: '飞利浦',
    status: 'active'
  },
  {
    id: 3,
    name: '手术刀片',
    code: 'SUR-001',
    category: 'surgical',
    specification: '10号',
    unit: '盒',
    price: 150,
    stock: 120,
    minStock: 50,
    supplier: '强生医疗',
    status: 'active'
  }
])

// 生命周期
onMounted(() => {
  fetchData()
})

// 获取数据
const fetchData = () => {
  loading.value = true
  // 模拟API调用
  setTimeout(() => {
    total.value = productList.value.length
    loading.value = false
  }, 500)
}

// 搜索
const handleSearch = () => {
  currentPage.value = 1
  fetchData()
}

// 重置搜索
const resetSearch = () => {
  searchForm.name = ''
  searchForm.category = ''
  currentPage.value = 1
  fetchData()
}

// 刷新数据
const refreshData = () => {
  fetchData()
}

// 分页大小变化
const handleSizeChange = (val) => {
  pageSize.value = val
  fetchData()
}

// 当前页变化
const handleCurrentChange = (val) => {
  currentPage.value = val
  fetchData()
}

// 获取类别标签
const getCategoryTag = (category) => {
  const map = {
    diagnostic: 'success',
    therapeutic: 'warning',
    monitoring: 'info',
    surgical: 'danger',
    consumable: 'default'
  }
  return map[category] || 'default'
}

// 获取类别文本
const getCategoryText = (category) => {
  const map = {
    diagnostic: '诊断设备',
    therapeutic: '治疗设备',
    monitoring: '监护设备',
    surgical: '手术器械',
    consumable: '耗材'
  }
  return map[category] || '未知'
}

// 格式化价格
const formatPrice = (price) => {
  return `¥${price.toLocaleString()}`
}

// 编辑产品
const handleEdit = (row) => {
  dialogTitle.value = '编辑产品'
  Object.assign(formData, row)
  showAddDialog.value = true
}

// 删除产品
const handleDelete = (row) => {
  ElMessageBox.confirm(
    `确定要删除产品"${row.name}"吗？`,
    '删除确认',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(() => {
    const index = productList.value.findIndex(item => item.id === row.id)
    if (index !== -1) {
      productList.value.splice(index, 1)
      ElMessage.success('删除成功')
      fetchData()
    }
  }).catch(() => {
    // 用户取消
  })
}

// 提交表单
const handleSubmit = () => {
  formRef.value?.validate((valid) => {
    if (valid) {
      if (formData.id) {
        // 更新
        const index = productList.value.findIndex(item => item.id === formData.id)
        if (index !== -1) {
          productList.value[index] = { ...formData }
        }
        ElMessage.success('更新成功')
      } else {
        // 新增
        const newId = Math.max(...productList.value.map(item => item.id)) + 1
        productList.value.push({
          ...formData,
          id: newId
        })
        ElMessage.success('新增成功')
      }
      showAddDialog.value = false
      resetForm()
      fetchData()
    }
  })
}

// 重置表单
const resetForm = () => {
  formData.id = ''
  formData.name = ''
  formData.code = ''
  formData.category = 'diagnostic'
  formData.specification = ''
  formData.unit = '个'
  formData.price = 0
  formData.stock = 0
  formData.minStock = 10
  formData.supplier = ''
  formData.status = 'active'
}
</script>

<style scoped>
.product-management {
  padding: 20px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header h2 {
  margin: 0;
  color: #333;
}

.search-area {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 4px;
  margin-bottom: 20px;
}

.table-area {
  background: white;
  padding: 20px;
  border-radius: 4px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.pagination {
  margin-top: 20px;
  text-align: right;
}

.low-stock {
  color: #f56c6c;
  font-weight: bold;
}
</style>