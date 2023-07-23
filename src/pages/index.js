// src/pages/index.js

import Table from '../components/Table'; 

const Home = ({ entries }) => (
  <div>
    <Table entries={entries} />
  </div>
);

Home.getInitialProps = async () => {
  let entries = [];
  try {
    const pCols = 'entry_id,entry_date,memo,debit,credit';
    const pWh = encodeURIComponent(JSON.stringify([{"col":"entry_id","comparisonOperator":"<","value":"30000"},{"logicOperator":"AND","col":"memo","comparisonOperator":"ILIKE","value":"reembolso"}]));
    // const pWh = '';
    const pOb = encodeURIComponent(JSON.stringify([{"col":"entry_date","direction":"DESC"},{"col":"entry_id","direction":"DESC"}]));
    // const pOb = '';
    const res = await fetch(`http://localhost:3000/api/entries?pCols=${pCols}&pWh=${pWh}&pOb=${pOb}`);
    entries = await res.json();
  } catch(error) {
    console.log(error);
  }
  console.log(entries);
  return { entries };
};

export default Home;
