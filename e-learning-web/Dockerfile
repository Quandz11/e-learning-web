FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

ARG VITE_API_URL
ARG VITE_API_PRIMARY_URL
ARG VITE_API_FALLBACK_URL

ENV VITE_API_URL=${VITE_API_URL}
ENV VITE_API_PRIMARY_URL=${VITE_API_PRIMARY_URL}
ENV VITE_API_FALLBACK_URL=${VITE_API_FALLBACK_URL}

RUN npm run build

FROM nginx:alpine AS final

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
