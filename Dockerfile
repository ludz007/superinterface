############################################
# Stage 1: Builder – install dependencies & build all packages
############################################
FROM node:18-alpine AS builder

# 1) Set the working directory to the repo root
WORKDIR /app

# 2) Copy only the files needed to install dependencies
#    (including turbo.json so npm knows about workspaces)
COPY package.json package-lock.json turbo.json ./

# 3) Install all dependencies (including devDependencies for each workspace)
#    This is crucial as build tools like 'typescript' and 'tsup' are devDependencies.
RUN npm install

# 4) Copy the rest of the repo to /app
#    This is done after npm install to leverage Docker's layer caching.
COPY . .

# 5) Run the “build” script from the root (Turbo will build every workspace)
#    This will correctly use the 'tsup' and 'typescript' packages from your node_modules.
RUN npm run build

# 6) Prune devDependencies after the build is complete.
#    This removes all development-only packages, reducing the size of node_modules
#    for the final production image.
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
#    These are hoisted to the root in a monorepo.
COPY --from=builder /app/node_modules ./node_modules

# 4) Copy the root package.json, which can be needed by Next.js.
COPY --from=builder /app/package.json ./package.json

# 5) Copy only what’s needed for the Next.js app from the builder:
#    • the built .next/ folder for the app
#    • the public/ folder for the app
#    • the app’s package.json so “npm start” works
#    (Assuming your deployable app is in 'packages/app')
COPY --from=builder /app/packages/app/.next ./packages/app/.next
COPY --from=builder /app/packages/app/public ./packages/app/public
COPY --from=builder /app/packages/app/package.json ./packages/app/package.json

# 6) Switch into the app’s folder for runtime
WORKDIR /app/packages/app

# 7) Expose port 3000 (Next.js default)
EXPOSE 3000

# 8) Start the Next.js server using the script from 'packages/app/package.json'
CMD ["npm", "start"]
