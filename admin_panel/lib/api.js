const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

/**
 * API helper - makes authenticated requests to the backend
 */
class ApiClient {
  constructor() {
    this.baseUrl = API_BASE_URL;
  }

  getToken() {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('admin_token');
    }
    return null;
  }

  setToken(token) {
    if (typeof window !== 'undefined') {
      localStorage.setItem('admin_token', token);
    }
  }

  clearToken() {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('admin_token');
    }
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}${endpoint}`;
    const token = this.getToken();

    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers
      },
      ...options
    };

    try {
      const response = await fetch(url, config);
      const data = await response.json();

      if (!response.ok) {
        if (response.status === 401) {
          this.clearToken();
          if (typeof window !== 'undefined') {
            window.location.href = '/login';
          }
        }
        throw new Error(data.message || 'Something went wrong');
      }

      return data;
    } catch (error) {
      throw error;
    }
  }

  // Auth
  async login(email, password) {
    const data = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password })
    });
    if (data.success && data.data.token) {
      this.setToken(data.data.token);
    }
    return data;
  }

  async getMe() {
    return this.request('/auth/me');
  }

  // Dashboard
  async getDashboard() {
    return this.request('/admin/dashboard');
  }

  // Users
  async getUsers(page = 1, search = '', isBot = '') {
    let url = `/admin/users?page=${page}&search=${search}`;
    if (isBot !== '') {
      url += `&isBot=${isBot}`;
    }
    return this.request(url);
  }

  async toggleUser(userId) {
    return this.request(`/admin/users/${userId}/toggle`, { method: 'PUT' });
  }

  // Deposits
  async getDeposits(status = 'pending') {
    return this.request(`/admin/deposits?status=${status}`);
  }

  async processDeposit(depositId, action, adminNote = '') {
    return this.request(`/admin/deposits/${depositId}`, {
      method: 'PUT',
      body: JSON.stringify({ action, adminNote })
    });
  }

  // Withdrawals
  async getWithdrawals(status = 'pending') {
    return this.request(`/admin/withdrawals?status=${status}`);
  }

  async processWithdrawal(withdrawalId, action, adminNote = '') {
    return this.request(`/admin/withdrawals/${withdrawalId}`, {
      method: 'PUT',
      body: JSON.stringify({ action, adminNote })
    });
  }

  // Lotteries
  async getLotteries() {
    return this.request('/admin/lotteries');
  }

  async getLotteryDetail(id) {
    return this.request(`/admin/lotteries/${id}`);
  }

  async createLottery(lotteryData) {
    return this.request('/admin/lotteries', {
      method: 'POST',
      body: JSON.stringify(lotteryData)
    });
  }

  async updateLottery(id, updateData) {
    return this.request(`/admin/lotteries/${id}`, {
      method: 'PUT',
      body: JSON.stringify(updateData)
    });
  }

  async drawLottery(id, drawData = null) {
    let body = null;
    if (drawData) {
      if (Array.isArray(drawData)) {
        body = { winningNumbers: drawData };
      } else {
        body = drawData;
      }
    }
    return this.request(`/admin/lotteries/${id}/draw`, {
      method: 'POST',
      ...(body && { body: JSON.stringify(body) })
    });
  }

  // Users Edit (Wallet & Password)
  async updateUserWallet(userId, balance) {
    return this.request(`/admin/users/${userId}/wallet`, {
      method: 'PUT',
      body: JSON.stringify({ balance })
    });
  }

  async updateUserWinningWallet(userId, winningBalance) {
    return this.request(`/admin/users/${userId}/wallet`, {
      method: 'PUT',
      body: JSON.stringify({ winningBalance })
    });
  }

  async changeUserPassword(userId, password) {
    return this.request(`/admin/users/${userId}/password`, {
      method: 'PUT',
      body: JSON.stringify({ password })
    });
  }

  // Announcements
  async getAnnouncements() {
    return this.request('/admin/announcements');
  }

  async createAnnouncement(announcementData) {
    return this.request('/admin/announcements', {
      method: 'POST',
      body: JSON.stringify(announcementData)
    });
  }

  async updateAnnouncement(id, announcementData) {
    return this.request(`/admin/announcements/${id}`, {
      method: 'PUT',
      body: JSON.stringify(announcementData)
    });
  }

  async deleteAnnouncement(id) {
    return this.request(`/admin/announcements/${id}`, {
      method: 'DELETE'
    });
  }

  // UPI Settings
  async getUPISettings() {
    return this.request('/admin/settings/upi');
  }

  async updateUPISettings(upiData) {
    return this.request('/admin/settings/upi', {
      method: 'PUT',
      body: JSON.stringify(upiData)
    });
  }

  // Support Chat
  async getChatUsers() {
    return this.request('/admin/chat/users');
  }

  async getChatHistory(userId) {
    return this.request(`/admin/chat/${userId}`);
  }

  async sendChatMessage(userId, text) {
    return this.request(`/admin/chat/${userId}`, {
      method: 'POST',
      body: JSON.stringify({ text })
    });
  }
}

const api = new ApiClient();
export default api;

