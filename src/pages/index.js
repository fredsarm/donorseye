// src/pages/index.js

import Table from '../components/Table'; 

const Home = ({ data, dictData }) => (
  <div>
    <Table data={data} dictData={dictData} />
  </div>
);

Home.getInitialProps = async () => {
  let data = [];
  let dictData = {};
  try {
    const pCols = 'entry_id,entry_date,memo,debit,credit';
    // const pWh = encodeURIComponent(JSON.stringify([{"col":"entry_id","comparisonOperator":"<","value":"30000"},{"logicOperator":"AND","col":"memo","comparisonOperator":"<>","value":"reembolso"}]));
    const pWh = encodeURIComponent(JSON.stringify([{"col":"entry_id","comparisonOperator":"<","value":"3000"}]));
    const pOb = encodeURIComponent(JSON.stringify([{"col":"entry_id","direction":"ASC"},{"col":"entry_date","direction":"ASC"}]));
    const language = 'en_us';
    const res = await fetch(`http://localhost:3000/api/entries?pCols=${pCols}&pWh=${pWh}&pOb=${pOb}&language=${language}`);
    const result = await res.json();
    data = result.data;
    dictData = result.dictData.reduce((acc, cur) => {
       acc[cur.col_name] = cur[language];
       return acc;
     }, {});
  } catch(error) {
    console.log(error);
  }
  return { data, dictData };
};

export default Home;