import * as React from "react";
import { connect } from "react-redux";
import { push } from "react-router-redux";

import {
  Datagrid,
  List,
  TextField,
  CreateButton,
  ExportButton,
  ReferenceField,
  DateField,
} from "react-admin";
import { withStyles } from "@material-ui/styles";
import { Route } from "react-router";
import { Drawer, Toolbar, Modal, Backdrop, Fade } from "@material-ui/core";
import { AccountCreate, AccountEdit }  from "./";

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
  onUnselectItems,
  resource,
  selectedIds,
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
      {/* <Button color="primary" onClick={customAction}>Custom Action</Button> */}
  </Toolbar>
);

const styles = {
  modal: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  paper: {
    border: '2px solid #000',
  },
};

class AccountList extends React.Component<AccountProps> {
  render() {
    const props = this.props;
    const classes = props.classes;

    return (
      <React.Fragment>
      <List {...props} actions={<AccountActions {...props}/>}>
        <Datagrid rowClick="edit">
          <TextField source="id" />
          <ReferenceField source="exchange_id" reference="exchanges">
            <TextField source="id" />
          </ReferenceField>
          <TextField source="name" />
          <DateField source="created_at" />
          <DateField source="updated_at" />
          <TextField source="api_key" />
          <TextField source="api_secret" />
        </Datagrid>
      </List>
      <Route
        path="/accounts/create"
        component={() => (
          <Modal open onClose={this.handleClose}
          aria-labelledby="transition-modal-title"
          aria-describedby="transition-modal-description"
          className={classes.modal}
          >
            <AccountCreate {...props} className={classes.paper} />
          </Modal>
        )}
      />
      <Route path="/accounts/:id"
        component={({match}) => {
          const isMatch = match && match.params && match.params.id !== "create";

          if(isMatch) {
            return (
              <Modal open onClose={this.handleClose}
              aria-labelledby="transition-modal-title"
              aria-describedby="transition-modal-description"
              className={classes.modal}
              >
                  <AccountEdit
                    id={match.params.id}
                    onCancel={this.handleClose}
                    {...props}
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
    this.props.history.push("/accounts");
  };
}

export default connect(
  undefined,
  { push }
)(withStyles(styles)(AccountList));
