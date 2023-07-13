import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useTable } from 'react-table';

function App() {
  const [data, setData] = useState([]);
  const [columns, setColumns] = useState([]);

  useEffect(() => {
    axios.get('/api/accEveEntries?select[]=*&orderBy[0][column]=entry_id&orderBy[0][direction]=asc')
      .then(response => {
        setData(response.data);
        if (response.data.length > 0) {
          setColumns(Object.keys(response.data[0]).map(key => {
            return {
              Header: key,
              accessor: key
            }
          }));
        }
      });
  }, []);

  const {
    getTableProps,
    getTableBodyProps,
    headerGroups,
    rows,
    prepareRow,
  } = useTable({ columns, data })

  return (
    <div className="App">
      <table {...getTableProps()} style={{ border: 'solid 1px blue' }}>
        <thead>
          {headerGroups.map(headerGroup => (
            <tr {...headerGroup.getHeaderGroupProps()}>
              {headerGroup.headers.map(column => (
                <th {...column.getHeaderProps()} style={{ borderBottom: 'solid 3px red', background: 'aliceblue', color: 'black', fontWeight: 'bold', }}>
                  {column.render('Header')}
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody {...getTableBodyProps()}>
          {rows.map((row, i) => {
            prepareRow(row);
            return (
              <tr {...row.getRowProps()}>
                {row.cells.map(cell => {
                  return <td {...cell.getCellProps()} style={{ padding: '10px', border: 'solid 1px gray' }}>{cell.render('Cell')}</td>
                })}
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

export default App;
