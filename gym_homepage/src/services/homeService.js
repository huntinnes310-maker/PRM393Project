import apiClient from './apiClient.js'

export async function getHomeData(userId) {
  const { data } = await apiClient.get(`/api/home/${userId}`)
  return data
}
