import type { NextConfig } from "next";

const config: NextConfig = {
	transpilePackages: ["@dimed/shared-types", "@dimed/ui"],
};

export default config;
