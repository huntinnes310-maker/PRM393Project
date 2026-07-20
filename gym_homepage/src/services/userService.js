import apiClient from './apiClient.js'

export async function getUserById(id) {
  const { data } = await apiClient.get(`/api/User/${id}`)
  return data
}
