"use strict";
{
const config=window.PUSH_CONFIG||{},button=document.querySelector("#enablePushButton"),status=document.querySelector("#pushStatus"),configured=/^[0-9a-f-]{36}$/i.test(config.oneSignalAppId||"");
let sdk=null,lastUser=null,syncing=false;
const setStatus=(text,enabled=false)=>{status.textContent=text;status.classList.toggle("enabled",enabled)};
const isIOS=()=>/iPad|iPhone|iPod/.test(navigator.userAgent),isStandalone=()=>window.matchMedia("(display-mode: standalone)").matches||navigator.standalone===true;
const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function syncStatus(){
  if(!sdk||syncing)return;syncing=true;
  try{
    if(window.currentUserId&&window.currentUserId!==lastUser){lastUser=window.currentUserId;await sdk.login(lastUser)}
    if(!sdk.Notifications.isPushSupported())return setStatus("Trình duyệt này không hỗ trợ thông báo đẩy");
    if(isIOS()&&!isStandalone())return setStatus("Trên iPhone: hãy thêm app vào Màn hình chính rồi mở từ biểu tượng");
    const permission=Boolean(sdk.Notifications.permission),subscribed=Boolean(sdk.User.PushSubscription.optedIn),subscriptionId=sdk.User.PushSubscription.id;
    if(permission&&subscribed&&subscriptionId){setStatus("Đã bật trên thiết bị này",true);button.textContent="✓ Đã bật"}
    else if(Notification.permission==="denied")setStatus("Quyền đã bị chặn. Hãy bật lại trong Cài đặt điện thoại");
    else setStatus("Chưa bật trên thiết bị này");
  }catch(error){setStatus(`Lỗi kiểm tra: ${error.message}`)}finally{syncing=false}
}
if(!configured){setStatus("Quản trị viên chưa cấu hình OneSignal");button.disabled=true}
else{
  window.OneSignalDeferred=window.OneSignalDeferred||[];
  window.OneSignalDeferred.push(async OneSignal=>{
    try{
      sdk=OneSignal;
      await OneSignal.init({appId:config.oneSignalAppId,serviceWorkerPath:"service-worker.js",serviceWorkerParam:{scope:"/"},allowLocalhostAsSecureOrigin:true});
      OneSignal.User.PushSubscription.addEventListener("change",syncStatus);
      setInterval(syncStatus,1500);await syncStatus();
    }catch(error){setStatus(`OneSignal chưa khởi động: ${error.message}`);button.disabled=true}
  });
}
button.addEventListener("click",async()=>{
  if(!sdk)return setStatus("OneSignal đang tải, hãy thử lại sau vài giây");
  if(isIOS()&&!isStandalone())return setStatus("Hãy thêm website vào Màn hình chính và mở từ biểu tượng app");
  try{
    button.disabled=true;setStatus("Đang yêu cầu quyền thông báo...");
    if(window.currentUserId)await sdk.login(window.currentUserId);
    if(!sdk.Notifications.permission)await sdk.Notifications.requestPermission();
    if(!sdk.Notifications.permission){setStatus(Notification.permission==="denied"?"Bạn đã chặn thông báo. Hãy bật lại trong Cài đặt điện thoại":"Bạn chưa chọn Cho phép thông báo");return}
    await sdk.User.PushSubscription.optIn();
    for(let i=0;i<10&&!sdk.User.PushSubscription.id;i++)await sleep(500);
    await syncStatus();
    if(!sdk.User.PushSubscription.optedIn||!sdk.User.PushSubscription.id)setStatus("Đã cấp quyền nhưng chưa đăng ký được thiết bị. Hãy đóng và mở lại app")
  }catch(error){setStatus(`Không bật được: ${error.message}`)}finally{button.disabled=false}
});
window.sendPhonePush=async notice=>{if(!configured||!window.thxCloudRequest)return;try{await window.thxCloudRequest("/functions/v1/send-push-notification",{method:"POST",body:JSON.stringify({title:notice.title,content:notice.content,type:notice.type,location:notice.location,event_time:notice.event_time})})}catch(error){console.warn("Thông báo trong app đã lưu nhưng push chưa gửi:",error.message)}};
}
