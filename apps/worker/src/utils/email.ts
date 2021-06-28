// @ts-ignore
// import sgTransport from "nodemailer-sendgrid-transport";
import chalk from "chalk";
import { promises as fsp } from "fs";
import * as nodemailer from "nodemailer";
import config from "./config";

const {
  mail: { sendGridApiKey },
  environment: { isTest, isDev },
} = config;

const { readFile, writeFile } = fsp;

let transporterPromise: Promise<nodemailer.Transporter>;
const etherealFilename = `${process.cwd()}/.ethereal`;

let logged = false;

export default function getTransport(): Promise<nodemailer.Transporter> {
  if (!transporterPromise) {
    transporterPromise = (async () => {
      if (isTest) {
        return nodemailer.createTransport({
          jsonTransport: true,
        });
      } else if (isDev) {
        let account;
        try {
          const testAccountJson = await readFile(etherealFilename, "utf8");
          account = JSON.parse(testAccountJson);
        } catch (e) {
          account = await nodemailer.createTestAccount();
          await writeFile(etherealFilename, JSON.stringify(account));
        }
        if (!logged) {
          logged = true;
          console.log();
          console.log();
          console.log(
            chalk.bold(
              " ✉️ Emails in development are sent via ethereal.email; your credentials follow:"
            )
          );
          console.log("  Site:     https://ethereal.email/login");
          console.log(`  Username: ${account.user}`);
          console.log(`  Password: ${account.pass}`);
          console.log();
          console.log();
        }
        return nodemailer.createTransport({
          host: "smtp.ethereal.email",
          port: 587,
          secure: false,
          auth: {
            user: account.user,
            pass: account.pass,
          },
        });
      } else {
        // if (!sendGridApiKey) {
        //   throw new Error("Misconfiguration: no SENDGRID_API_KEY");
        // }
        // return nodemailer.createTransport(
        //   sgTransport({
        //     auth: { api_key: sendGridApiKey },
        //   })
        // );
                return nodemailer.createTransport({
          host: "smtp.ethereal.email",
          port: 587,
          secure: false,
          auth: {
            // user: account.user,
            // pass: account.pass,
          },
        });
      }
    })();
  }
  return transporterPromise!;
}
