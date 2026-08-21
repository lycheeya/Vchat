import { http } from "@kit.NetworkKit";
import { ChatResponse } from "../models/chat";
const req = http.createHttp()

export async function getRequestMessage(content:string) {
  try {
    const res = await req.request(`http://api.qingyunke.com/api.php?key=free&appid=0&msg=${encodeURIComponent(content)}`)
    return JSON.parse(res.result as string) as ChatResponse
  }catch (error){
    return Promise.reject(error)
  } finally {
    req.destroy
  }


}