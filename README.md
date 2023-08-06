This is a Next.js project bootstrapped with create-next-app. This project serves as a study in which I'm exploring various technology options that can be used for the creation of enterprise systems leveraging the JavaScript environment.

**Technologies Used:**

- Node.js
- PostgreSQL
- JavaScript
- pg-promise
- Next.js
- React
- [Ant Design](https://ant.design/)

**Getting Started**

- Clone the repository.
- Navigate to the project directory and run:

``````bash
 npm install
``````
- Install PostgreSQL.
- While logged in as an administrative user (usually 'postgres'):
  - Create the role 'derole', set the password as indicated in the accountingConn.js file.
  - Create the 'de' database and assign its ownership to the 'derole' user.
  - Restore the backup from the file located at /dbackup/db/sql.
- In the project directory, run:

``````bash
 npm run dev
``````
- Open http://localhost:3000 with your browser to see the result.
- Make me happy with a feedback! 🙏🏻