############################################
# Stage 1: Build Stage
############################################
FROM node:18-alpine AS builder

# 1) Set working directory
WORKDIR /app

# 2) Copy package.json and lockfile (package-lock.json) if it exists
COPY package.json ./
# If there is a package-lock.json (npm lock), copy it. If not, this step does nothing.
COPY package-lock.json ./

# 3) Install dependencies via npm
# We do not use pnpm here, because this project is configured for npm
RUN npm install

# 4) Copy all source files
COPY . .

# 5) Generate Prisma client and run migrations
# (If your repo has a Prisma schema, this will create the client and apply migrations;
#  if not, it will simply run the command and continue.)
RUN npx prisma generate \
    && npx prisma migrate deploy

# 6) Build the Next.js application
# (Most Next/Node projects use 'npm run build' to compile into .next/)
RUN npm run build


############################################
# Stage 2: Production Runtime Stage
############################################
FROM node:18-alpine

# 1) Create working directory in the final image
WORKDIR /app

# 2) Copy only the built assets and node_modules from the builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

# 3) Expose port 3000 (Superinterface runs on port 3000 by default)
EXPOSE 3000

# 4) Set NODE_ENV=production (ensures we’re in “production” mode)
ENV NODE_ENV=production

# 5) Final command to start the Next.js app
CMD ["npm", "start"]
