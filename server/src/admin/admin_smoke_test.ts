import Database from "better-sqlite3";
import { initializeSchema } from "../db/schema.js";
import { AdminRepository } from "./admin_repository.js";

const db = new Database(":memory:");
initializeSchema(db);
const now = new Date().toISOString();
db.prepare("INSERT INTO players(player_id,display_name,created_at,updated_at) VALUES(?,?,?,?)").run("admin_test","Owner Test",now,now);
db.prepare("INSERT INTO wallets(player_id,chips,gems,updated_at) VALUES(?,?,?,?)").run("admin_test",100,20,now);
db.prepare("INSERT INTO player_progression(player_id,total_xp,level,title_id,created_at,updated_at) VALUES(?,?,?,?,?,?)").run("admin_test",0,1,"new_player",now,now);
const repo = new AdminRepository(db);
repo.adjustWallet("admin_test","chips",50,"测试增加");
repo.adjustWallet("admin_test","chips",-125,"测试扣除");
let rejected=false;
try { repo.adjustWallet("admin_test","chips",-100,"余额不足测试"); } catch { rejected=true; }
if(!rejected) throw new Error("insufficient balance was not rejected");
const wallet=db.prepare("SELECT chips FROM wallets WHERE player_id=?").get("admin_test") as {chips:number};
if(wallet.chips!==25) throw new Error("wallet adjustment failed");
const counts=db.prepare("SELECT (SELECT COUNT(*) FROM wallet_transactions) tx,(SELECT COUNT(*) FROM admin_audit_logs) audits").get() as {tx:number;audits:number};
if(counts.tx!==2||counts.audits!==2) throw new Error("ledger/audit coverage failed");
repo.setXp("admin_test",450,"XP 补偿");
repo.moderate("admin_test",true,"测试封禁");
repo.moderate("admin_test",false,"测试解封");
if((repo.player("admin_test")?.is_banned)!==0) throw new Error("unban failed");
console.log("admin smoke: ok");
db.close();
