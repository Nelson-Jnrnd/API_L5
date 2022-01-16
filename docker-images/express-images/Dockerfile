FROM node:current
EXPOSE 4242
WORKDIR /opt/app
COPY src/ .
RUN npm install
CMD ["node", "index.js"]