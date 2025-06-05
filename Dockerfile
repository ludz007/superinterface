############################################
# Stage 1: “builder” – install & build everything
############################################
FROM node:18-alpine AS builder

# 1) Set working directory at the monorepo root
WORKDIR /app

# 2) Copy only the files needed to install dependencies:
#    • package.json (root)
#    • package-lock.json (root)  ← makes npm install reproducible
#    • turbo.json   (root)      ← for workspace definitions
COPY package.json package-lock.json turbo.json ./

# 3) Run npm install at the root. This installs all workspaces under /packages.
RUN npm install

# 4) Copy the rest of the monorepo into the container
COPY . .

# 5) R un the build step from the root. 
#    This will compile every workspace, including your Next.js app.
RUN npm run build


############################################
# Stage 2: “runner” – copy only what we need and launch
############################################
FROM node:18-alpine AS runner

# 1) Create a clean working directory for the production image
WORKDIR /app

# 2) Copy built files & node_modules from the builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/app/.next ./packages/app/.next
COPY --from=builder /app/packages/app/public ./packages/app/public
COPY --from=builder /app/packages/app/package.json ./packages/app/package.json

# 3) If you have any other “static” output folders, copy them too.
#    For example, if turbo built other packages, you can bring over only the bits you need.
#    Here, we assume that the Next.js app lives in packages/app, so we copied its .next/ and public/.

# 4) Switch into the Next.js app folder (packages/app) for runtime
WORKDIR /app/packages/app

# 5) Set NODE_ENV=production so Next.js serves in production mode
ENV NODE_ENV=production

# 6) Expose port 3000 (the default Next.js port)
EXPOSE 3000

# 7) Start the Next.js app
CMD ["npm", "start"]
