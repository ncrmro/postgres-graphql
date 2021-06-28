interface Config {
  projectName: string;
  environment: { isTest: boolean; isDev: boolean };
  mail: {
    sendGridApiKey?: string;
    fromEmail: string;
    legalText: string;
  };
}

const config: Config = {
  projectName: "JTX",
  environment: {
    // isTest: process.env.NODE_ENV === "test",
    // isDev: process.env.NODE_ENV !== "production",
    isTest: false,
    isDev: false,
  },
  mail: {
    sendGridApiKey: process.env.SENDGRID_API_KEY,
    fromEmail: "noreply@jtronics.exchange",
    legalText: "",
  },
};

export default {
  projectName: "JTX",
  environment: {
    isTest: process.env.NODE_ENV === "test",
    isDev: process.env.NODE_ENV !== "production",
  },
  mail: {
    sendGridApiKey: process.env.SENDGRID_API_KEY,
    fromEmail: "noreply@jtronics.exchange",
    legalText: "",
  },
} as Config;
