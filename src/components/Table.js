// components/Table.js

import React from 'react';

const Table = ({ data, dictData }) => {
  const columnNames = data[0] && Object.keys(data[0]);


  return (
    <table>
      <thead>
        <tr>
          {columnNames && columnNames.map(name => <th key={name} data-colname={name}>{dictData[name] || name}</th>)}
        </tr>
      </thead>
      <tbody>
        {data.map((entry, index) => (
          <tr key={index}>
            {columnNames.map(name => <td key={`${index}-${name}`} data-colname={name}>{entry[name]}</td>)}
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default Table;