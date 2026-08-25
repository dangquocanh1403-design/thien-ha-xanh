"use strict";
{
const q=s=>document.querySelector(s),roleNames={leader:"Nhóm trưởng",deputy:"Nhóm phó",member:"Thành viên"},typeNames={hospital:"Trực viện",donation_site:"Trực điểm hiến máu"};
const esc=value=>{const d=document.createElement("div");d.textContent=value??"";return d.innerHTML};
const call=(path,options)=>window.thxCloudRequest(path,options);
const isLeader=()=>["leader","deputy"].includes(window.currentManagerProfile?.role);
const format=value=>new Date(value).toLocaleString("vi-VN",{hour:"2-digit",minute:"2-digit",day:"2-digit",month:"2-digit",year:"numeric"});
async function loadDuties(){
  q("#dutyMessage").textContent="Đang tải lịch trực...";
  try{
    const schedules=await call("/rest/v1/duty_schedules?select=*&order=starts_at.asc"),registrations=await call("/rest/v1/duty_registrations?select=*&order=created_at.asc");
    q("#dutyMessage").textContent="";
    q("#dutyList").innerHTML=schedules.length?schedules.map(schedule=>renderDuty(schedule,registrations.filter(r=>r.schedule_id===schedule.id))).join(""):"<p>Chưa có lịch trực nào được tạo.</p>";
  }catch(error){const missing=/schema cache|duty_schedules/i.test(error.message);q("#dutyMessage").textContent=missing?"Chưa cài đặt dữ liệu lịch trực. Hãy chạy file supabase-dang-ky-lich-truc.sql trong Supabase SQL Editor.":`Không tải được lịch: ${error.message}`}
}
function renderDuty(schedule,people){
  const mine=people.some(p=>p.user_id===window.currentUserId),full=people.length>=schedule.capacity,ended=new Date(schedule.ends_at)<=new Date(),canRegister=["leader","deputy","member"].includes(window.currentManagerProfile?.role);
  const names=people.length?people.map(p=>`<span>${esc(p.display_name)} · ${roleNames[p.role]||p.role}</span>`).join(""):"<small>Chưa có người đăng ký.</small>";
  const action=mine?`<button class="cancel" data-cancel-duty="${schedule.id}">Hủy đăng ký</button>`:`<button class="register" data-register-duty="${schedule.id}" ${full||ended||!canRegister?"disabled":""}>${ended?"Đã kết thúc":full?"Đã đủ người":"Đăng ký tham gia"}</button>`;
  return `<article class="duty-card ${schedule.duty_type}"><header><div><h3>${typeNames[schedule.duty_type]}</h3><time>🕒 ${format(schedule.starts_at)} – ${format(schedule.ends_at)}</time><span class="place">📍 ${esc(schedule.location)}</span></div><span class="capacity">${people.length}/${schedule.capacity} người</span></header>${schedule.note?`<p>${esc(schedule.note)}</p>`:""}<div class="registrants">${names}</div><div class="duty-actions">${action}${isLeader()?`<button data-delete-duty="${schedule.id}">Xóa lịch</button>`:""}</div></article>`;
}
const openDutyDialog=()=>{q("#dutyDialog").showModal();q("#dutyForm").hidden=!isLeader();loadDuties()};
q("#dutyButton").onclick=openDutyDialog;
q("#mobileDutyButton").onclick=openDutyDialog;
q("#closeDuty").onclick=()=>q("#dutyDialog").close();
q("#dutyForm").onsubmit=async event=>{event.preventDefault();const start=new Date(q("#dutyStart").value),end=new Date(q("#dutyEnd").value);if(end<=start)return q("#dutyMessage").textContent="Thời gian kết thúc phải sau thời gian bắt đầu.";try{await call("/rest/v1/duty_schedules",{method:"POST",headers:{Prefer:"return=minimal"},body:JSON.stringify({duty_type:q("#dutyType").value,location:q("#dutyLocation").value.trim(),starts_at:start.toISOString(),ends_at:end.toISOString(),capacity:Number(q("#dutyCapacity").value),note:q("#dutyNote").value.trim(),created_by:window.currentUserId})});event.target.reset();q("#dutyCapacity").value="10";await loadDuties()}catch(error){q("#dutyMessage").textContent=error.message}};
q("#dutyList").onclick=async event=>{const register=event.target.closest("[data-register-duty]"),cancel=event.target.closest("[data-cancel-duty]"),remove=event.target.closest("[data-delete-duty]");try{if(register)await call("/rest/v1/rpc/register_for_duty",{method:"POST",body:JSON.stringify({p_schedule_id:register.dataset.registerDuty})});if(cancel)await call("/rest/v1/rpc/cancel_duty_registration",{method:"POST",body:JSON.stringify({p_schedule_id:cancel.dataset.cancelDuty})});if(remove&&confirm("Xóa lịch trực này và toàn bộ lượt đăng ký?"))await call(`/rest/v1/duty_schedules?id=eq.${remove.dataset.deleteDuty}`,{method:"DELETE",headers:{Prefer:"return=minimal"}});await loadDuties()}catch(error){q("#dutyMessage").textContent=error.message}};
}
