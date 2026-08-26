import { createClient } from "jsr:@supabase/supabase-js@2";

const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, apikey, content-type"};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});

Deno.serve(async req=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
  if(req.method!=="POST")return json({error:"Method not allowed"},405);
  try{
    const auth=req.headers.get("Authorization")||"";
    const url=Deno.env.get("SUPABASE_URL")!,anon=Deno.env.get("SUPABASE_ANON_KEY")!,service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const userClient=createClient(url,anon,{global:{headers:{Authorization:auth}}});
    const {data:{user},error:userError}=await userClient.auth.getUser();
    if(userError||!user)return json({error:"Chưa đăng nhập"},401);
    const admin=createClient(url,service);
    const {data:profile}=await admin.from("manager_profiles").select("role,status").eq("user_id",user.id).single();
    if(!profile||profile.status!=="approved"||!["leader","deputy"].includes(profile.role))return json({error:"Chỉ nhóm trưởng hoặc nhóm phó được gửi thông báo"},403);
    const body=await req.json(),title=String(body.title||"").trim(),content=String(body.content||"").trim();
    if(!title||!content)return json({error:"Thiếu tiêu đề hoặc nội dung"},400);
    const appId=Deno.env.get("ONESIGNAL_APP_ID"),apiKey=Deno.env.get("ONESIGNAL_REST_API_KEY");
    if(!appId||!apiKey)return json({error:"Máy chủ chưa cấu hình OneSignal"},500);
    const details=[body.location?`Địa điểm: ${body.location}`:"",body.event_time?`Thời gian: ${new Date(body.event_time).toLocaleString("vi-VN",{timeZone:"Asia/Ho_Chi_Minh"})}`:"",content].filter(Boolean).join("\n");
    const response=await fetch("https://api.onesignal.com/notifications",{method:"POST",headers:{"Content-Type":"application/json",Authorization:`Key ${apiKey}`},body:JSON.stringify({app_id:appId,target_channel:"push",included_segments:["Subscribed Users"],headings:{en:title,vi:title},contents:{en:details,vi:details},url:"https://thien-ha-xanh.onrender.com/"})});
    const result=await response.json();
    if(!response.ok)return json({error:result},502);
    return json({ok:true,result});
  }catch(error){return json({error:error instanceof Error?error.message:"Lỗi không xác định"},500)}
});
