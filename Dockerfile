############################################
# Stage 1: Builder – install dependencies & build all packages
############################################
FROM node:18-alpine AS builder

# 1) Set the working directory to the repo root
WORKDIR /app

# 2) Copy only the files needed to install dependencies
COPY package.json package-lock.json turbo.json ./

# 3) Install all dependencies (including devDependencies)
RUN npm install

# 4) FIX: Add the local node_modules binaries to the PATH
# This ensures that commands like 'tsup' are found by the shell.
ENV PATH /app/node_modules/.bin:$PATH

# 5) Copy the rest of the repo to /app
COPY . .

# 6) Run the “build” script from the root (Turbo will build every workspace)
# Now it will be able to find and execute 'tsup'
RUN npm run build

# 7) Prune devDependencies after the build is complete.
RUN npm prune --production


############################################
# Stage 2: Runner – copy only the production output & start Next.js
############################################
FROM node:18-alpine AS runner

# 1) Create a fresh working directory
WORKDIR /app

# 2) Ensure we’re in production mode
ENV NODE_ENV=production

# 3) Copy the pruned, production-only node_modules from the builder stage.
COPY --from=builder /app/node_modules ./node_modules

# 4) Copy the root package.json
COPY --from=builder /app/package.json ./package.json

# 5) Copy only what’s needed for the Next.js app from the builder:
COPY --from=builder /app/packages/app/.next ./packages/app/.next
COPY --from=builder /app/packages/app/public ./packages/app/public
COPY --from=builder /app/packages/app/package.json ./packages/app/package.json

# 6) Switch into the app’s folder for runtime
WORKDIR /app/packages/app

# 7) Expose port 3000 (Next.js default)
EXPOSE 3000

# 8) Start the Next.js server
CMD ["npm", "start"]
