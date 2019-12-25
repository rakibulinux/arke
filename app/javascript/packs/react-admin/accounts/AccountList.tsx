import * as React from 'react';
import { connect } from 'react-redux';
import { push } from 'react-router-redux';
import {
  List,
  TextField,
  CreateButton,
  ExportButton,
  ReferenceField,
} from 'react-admin';
import { Route } from 'react-router';
import { Toolbar, Modal } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import { AccountCreate, AccountEdit }  from './';
import { StyledDatagrid as Datagrid } from '../partials';

interface AccountProps {
  basePath: any;
  currentSort: any;
  displayedFilters: any;
  exporter: any;
  filters: any;
  filterValues: any;
  onUnselectItems: any;
  resource: any;
  selectedIds: any;
  showFilter: any;
  total: any;
  history: any;
  classes: any;
}

const AccountActions = ({
  basePath,
  currentSort,
  displayedFilters,
  exporter,
  filters,
  filterValues,
  resource,
  showFilter,
  total
}) => (
  <Toolbar>
      {filters && React.cloneElement(filters, {
          resource,
          showFilter,
          displayedFilters,
          filterValues,
          context: 'button',
      })}
      <CreateButton basePath={basePath} />
      <ExportButton
          disabled={total === 0}
          resource={resource}
          sort={currentSort}
          filter={filterValues}
          exporter={exporter}
      />
      {/* Add your custom actions */}
      {/* <Button color='primary' onClick={customAction}>Custom Action</Button> */}
  </Toolbar>
);

const useModalStyles = makeStyles({
  modal: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
});

class AccountList extends React.Component<AccountProps> {
  render() {
    const props = this.props;

    return (
      <React.Fragment>
      <List {...props} actions={<AccountActions {...props}/>}>
        <Datagrid rowClick='edit'>
          <TextField source='name' />
          <ReferenceField source='exchange_id' reference='exchanges' label='Driver'>
            <TextField source='name' />
          </ReferenceField>
          <TextField source='api_key' />
          <TextField label='Requests delay' />
          <TextField label='Status' />
          {/* <SimpleForm toolbar={null} label='Active'> */}
            {/* <BooleanInput source='_active' label=' /> */}
          {/* </SimpleForm> */}
          <TextField label='Actions' />
        </Datagrid>
      </List>
      <Route
        path='/accounts/create'
        component={() => (
          <Modal
            open
            onClose={this.handleClose}
            aria-labelledby='transition-modal-title'
            aria-describedby='transition-modal-description'
            className={useModalStyles(props).modal}
          >
            <AccountCreate {...props} />
          </Modal>
        )}
      />
      <Route path='/accounts/:id'
        component={({match}) => {
          const isMatch = match && match.params && match.params.id !== 'create';

          if(isMatch) {
            return (
              <Modal
                open
                onClose={this.handleClose}
                aria-labelledby='transition-modal-title'
                aria-describedby='transition-modal-description'
                className={useModalStyles(props).modal}
              >
                <AccountEdit
                  {...props}
                  id={match.params.id}
                  onCancel={this.handleClose}
                />
              </Modal>
            );
          }

          return null;
        }}
      />
    </React.Fragment>
    );
  }

  handleClose = () => {
    this.props.history.push('/accounts');
  };
}

export default connect(
  undefined,
  { push }
)(AccountList);
