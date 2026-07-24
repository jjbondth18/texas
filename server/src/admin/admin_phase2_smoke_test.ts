import Database from "better-sqlite3";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import { initializeSchema } from "../db/schema.js";
import { openAdminDatabase, validateProductionDatabasePath } from "./admin_startup.js";
import { AdminRepository } from "./admin_repository.js";
import { WalletRepository } from "../db/wallet_repository.js";

const root = resolve(process.cwd(), "data/admin-phase2-smoke");
const databasePath = resolve(root, "production.sqlite");
const backupDir = resolve(root, "backups");
rmSync(root, { recursive: true, force: true });
mkdirSync(root, { recursive: true });

let rejectedRelative = false;
try { validateProductionDatabasePath("production.sqlite", "production"); } catch { rejectedRelative = true; }
if (!rejectedRelative) throw new Error("relative SQLite path was not rejected");
let rejectedMissing = false;
try { validateProductionDatabasePath(resolve(root, "missing.sqlite"), "production"); } catch { rejectedMissing = true; }
if (!rejectedMissing) throw new Error("missing production SQLite database was not rejected");

const seed = new Database(databasePath);
initializeSchema(seed);
const now = new Date().toISOString();
seed.prepare("INSERT INTO players(player_id,display_name,created_at,updated_at) VALUES(?,?,?,?)").run("phase2","Phase Two",now,now);
seed.prepare("INSERT INTO wallets(player_id,chips,gems,updated_at) VALUES(?,?,?,?)").run("phase2",100,10,now);
seed.prepare("INSERT INTO player_progression(player_id,total_xp,level,title_id,created_at,updated_at) VALUES(?,?,?,?,?,?)").run("phase2",0,1,"new_player",now,now);
seed.close();

const opened = await openAdminDatabase({ sqlitePath: databasePath, backupDir, nodeEnv: "production", now: new Date("2026-07-24T12:00:00Z") });
if (!existsSync(opened.preMigrationBackup)) throw new Error("pre-migration backup missing");
const backup = new Database(opened.preMigrationBackup, { readonly: true });
const check = backup.pragma("integrity_check") as Array<{ integrity_check?: string }>;
if (check[0]?.integrity_check !== "ok") throw new Error("backup integrity check failed");
backup.close();

const second = new Database(databasePath);
second.pragma("journal_mode = WAL");
second.pragma("busy_timeout = 1000");
const repo = new AdminRepository(opened.db);
repo.adjustWallet("phase2","chips",25,"concurrent smoke grant");
const gameWallet = new WalletRepository(second);
opened.db.exec("BEGIN IMMEDIATE");
let busyRejected = false;
try { gameWallet.addGems("phase2",1,{reason:"locked_game_write"}); } catch (error) {
  busyRejected = (error as { code?: string }).code === "SQLITE_BUSY" || /database is (locked|busy)/i.test(String(error));
}
opened.db.exec("ROLLBACK");
const configuredTimeout = second.pragma("busy_timeout", { simple: true }) as number;
if (!busyRejected || configuredTimeout !== 1000) throw new Error("busy_timeout lock behavior was not enforced");
gameWallet.addGems("phase2",1,{reason:"concurrent_game_write"});
const balances = second.prepare("SELECT chips,gems FROM wallets WHERE player_id=?").get("phase2") as {chips:number;gems:number};
if (balances.chips !== 125 || balances.gems !== 11) throw new Error("concurrent database writes failed");
second.close();
opened.db.close();

let migrationStopped = false;
try {
  await openAdminDatabase({
    sqlitePath: databasePath,
    backupDir,
    nodeEnv: "production",
    migrationRunner: () => { throw new Error("simulated migration failure"); },
    now: new Date("2026-07-24T12:01:00Z"),
  });
} catch (error) {
  migrationStopped = String(error).includes("startup stopped");
}
if (!migrationStopped) throw new Error("migration failure did not stop startup");
if (!existsSync(resolve(backupDir, "pre-migration-2026-07-24T12-01-00-000Z.sqlite"))) throw new Error("failed migration did not retain pre-migration backup");

rmSync(root, { recursive: true, force: true });
console.log("admin phase2 smoke: ok");
