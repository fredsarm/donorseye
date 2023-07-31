import React from 'react';
import { Table } from 'antd';

const EntriesTable = ({ data, dictData, language }) => {
  const columnsModel = {
    'entry_parent': { 
      dataIndex: 'entry_parent', 
      sorter: (a, b) => a.entry_parent?.localeCompare(b.entry_parent) 
    },
    'entry_date': { 
      dataIndex: 'entry_date', 
      sorter: (a, b) => new Date(a.entry_date) - new Date(b.entry_date),
      render: (text, record) => new Date(text).toLocaleDateString(language.replace("_", "-"))
    },
    'credit': { 
      dataIndex: 'credit', 
      sorter: (a, b) => Number(a.credit) - Number(b.credit),
      render: (text, record) => Number(text).toLocaleString(language.replace("_", "-"), { minimumFractionDigits: 2 }),
      align: 'right'
    },
    'balance': { 
      dataIndex: 'balance', 
      sorter: (a, b) => Number(a.balance) - Number(b.balance),
      render: (text, record) => Number(text).toLocaleString(language.replace("_", "-"), { minimumFractionDigits: 2 }),
      align: 'right'
    },
    'entry_id': { 
      dataIndex: 'entry_id', 
      sorter: (a, b) => a.entry_id - b.entry_id,
      align: 'right' 
    },
    'acc_id': { 
      dataIndex: 'acc_id', 
      sorter: (a, b) => a.acc_id.localeCompare(b.acc_id) 
    },
    'user_id': { 
      dataIndex: 'user_id', 
      sorter: (a, b) => a.user_id.localeCompare(b.user_id) 
    },
    'debit': { 
      dataIndex: 'debit', 
      sorter: (a, b) => Number(a.debit) - Number(b.debit),
      render: (text, record) => Number(text).toLocaleString(language.replace("_", "-"), { minimumFractionDigits: 2 }),
      align: 'right'
    },
    'occur_date': { 
      dataIndex: 'occur_date', 
      sorter: (a, b) => new Date(a.occur_date) - new Date(b.occur_date),
      render: (text, record) => new Date(text).toLocaleDateString(language.replace("_", "-"))
    },
    'memo': { 
      dataIndex: 'memo', 
      sorter: (a, b) => a.memo.localeCompare(b.memo) 
    },
    'entity_id': {
      dataIndex: 'entity_id', 
      sorter: (a, b) => a.entity_id.localeCompare(b.entity_id) 
    }
  };
  
  // Gera as colunas dinamicamente com base no primeiro objeto no array de dados
  const columns = data.length > 0 
    ? Object.keys(data[0]).map(key => ({
      ...columnsModel[key],
      title: dictData[key] // use the title from the dictData
    }))
    : [];

  return (
    <Table columns={columns} dataSource={data} rowKey='entry_id' />
  );
};

export default EntriesTable;