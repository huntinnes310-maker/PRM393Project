import apiClient from './apiClient.js'

export async function getCustomerProfile(userId) {
  try {
    const { data } = await apiClient.get(`/api/customer/user/${userId}`)
    return data
  } catch (err) {
    if (err.response?.status === 404) return null
    throw err
  }
}
