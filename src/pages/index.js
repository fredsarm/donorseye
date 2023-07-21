import axios from 'axios';
import Table from '../components/Table';

const Home = ({ entries }) => (
  <div>
    <Table entries={entries} />
  </div>
);

Home.getInitialProps = async () => {
  let entries = [];
  try {
    const res = await axios.get('http://localhost:3000/api/entries');
    entries = res.data;
  } catch(error) {
    console.log(error);
  }
  console.log(entries);
  return { entries };
};

export default Home;
 
