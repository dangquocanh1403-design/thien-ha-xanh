"use strict";
{
const updateMembershipStatistics=()=>{
  const target=document.querySelector("#associationCount");
  if(!target)return;
  let people=[];
  try{people=JSON.parse(localStorage.getItem("thienHaXanhMembersV1"))||[]}catch{}
  for(const account of window.approvedManagerProfiles||[]){
    if(!people.some(person=>person.role===account.role))people.push({membership:account.membership||"volunteer"});
  }
  const volunteer=document.querySelector("#volunteerCount");
  if(volunteer)volunteer.textContent=people.filter(person=>person.membership==="volunteer").length;
  target.textContent=people.filter(person=>person.membership==="association").length;
};
const list=document.querySelector("#memberList");
if(list)new MutationObserver(updateMembershipStatistics).observe(list,{childList:true,subtree:true});
window.addEventListener("storage",updateMembershipStatistics);
updateMembershipStatistics();
}
