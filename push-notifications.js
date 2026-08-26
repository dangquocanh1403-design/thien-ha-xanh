"use strict";
{
const config=window.PUSH_CONFIG||{},button=document.querySelector("#enablePushButton"),status=document.querySelector("#pushStatus"),configured=/^[0-9a-f-]{36}$/i.test(config.oneSignalAppId||"");
let sdk=null,lastUser=null;
const setStatus=(text,enabled=false)=>{status.textContent=text;status.classList.toggle("enabled",enabled)};
if(!configured){setStatus("Quản trị viên chưa cấu hình OneSignal");button.disabled=true}
else{
  window.OneSignalDeferred=window.OneSignalDeferred||[];
  window.OneSignalDeferred.push(async OneSignal=>{
    sdk=OneSignal;
    await OneSignal.init({appId:config.oneSignalAppId,serviceWorkerPath:"service-worker.js",serviceWorkerParam:{scope:"/"},allowLocalhostAsSecureOrigin:true});
    const syncUser=async()=>{if(window.currentUserId&&window.currentUserId!==lastUser){lastUser=window.currentUserId;await OneSignal.login(lastUser)}const enabled=Boolean(OneSignal.User.PushSubscription.optedIn);setStatus(enabled?"Đã bật trên thiết bị này":"Chưa bật trên thiết bị này",enabled);button.textContent=enabled?"✓ Đã bật":"🔔 Bật thông báo"};
    OneSignal.User.PushSubscription.addEventListener("change",syncUser);
    setInterval(syncUser,1200);syncUser();
  });
}
button.addEventListener("click",async()=>{if(!sdk)return;try{button.disabled=true;if(window.currentUserId)await sdk.login(window.currentUserId);await sdk.User.PushSubscription.optIn();const enabled=Boolean(sdk.User.PushSubscription.optedIn);setStatus(enabled?"Đã bật trên thiết bị này":"Bạn chưa cấp quyền thông báo",enabled)}catch(error){setStatus(`Không bật được: ${error.message}`)}finally{button.disabled=false}});
window.sendPhonePush=async notice=>{if(!configured||!window.thxCloudRequest)return;try{await window.thxCloudRequest("/functions/v1/send-push-notification",{method:"POST",body:JSON.stringify({title:notice.title,content:notice.content,type:notice.type,location:notice.location,event_time:notice.event_time})})}catch(error){console.warn("Thông báo trong app đã lưu nhưng push chưa gửi:",error.message)}};
}
