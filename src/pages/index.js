import { useEffect, useState } from 'react';
import EntriesTable from './accounting/EntriesTable';

const Home = () => {
  const [data, setData] = useState([]);
  const [dictData, setDictData] = useState({});
  const [language, setLanguage] = useState({});

  useEffect(() => {
    const fetchData = async () => {
      try {
        const pCols = 'entry_id,entry_date,occur_date,memo,debit,credit,balance,user_id,entry_parent,entity_id,acc_id';
        const pWh = encodeURIComponent(JSON.stringify([{"col":"entry_id","comparisonOperator":"<","value":"30000"}]));
        const pOb = encodeURIComponent(JSON.stringify([{"col":"entry_id","direction":"ASC"},{"col":"entry_date","direction":"ASC"}]));
        const language = 'pt_br';
        let userLocale = navigator.language || navigator.userLanguage; // pega o idioma do navegador
console.log(userLocale);
        const res = await fetch(`http://localhost:3000/api/entries?pCols=${pCols}&pWh=${pWh}&pOb=${pOb}&language=${language}&userLocale=${userLocale}`);
        const result = await res.json();
        setData(result.data);
        setLanguage(language);
        setDictData(result.dictData.reduce((acc, cur) => {
          acc[cur.col_name] = cur[language];
          return acc;
        }, {}));
      } catch(error) {
        console.log(error);
      }
    };

    fetchData();
  }, []);

  return (
    <div>
      <EntriesTable data={data} dictData={dictData} language={language}/>
    </div>
  );
};

export default Home;