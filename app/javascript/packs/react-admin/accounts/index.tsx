import * as React from 'react';
import {
  Create,
  Edit,
  SimpleForm,
  ReferenceInput,
  Toolbar,
  SaveButton,
} from 'react-admin';

import { StyledSelectInput, StyledTextInput, StyledNumberInput } from '../partials';
import { makeStyles } from '@material-ui/core/styles';
import { CardHeader } from '@material-ui/core';

const useToolbarStyles = makeStyles({
  toolbar: {
    display: 'flex',
    justifyContent: 'space-between',
    backgroundColor: 'inherit',
    marginTop: '0px',
    padding: '0 16px',
  }
});

const useButtonStyles = makeStyles({
  button: {
    width: '100%',
    padding: '8px 0px'
  }
});

const AccountToolbar = props => (
  <Toolbar {...props} classes={useToolbarStyles(props)}>
    <SaveButton
      classes={useButtonStyles(props)}
      icon={<React.Fragment />}
      label="SAVE"
    />
  </Toolbar>
);

const AccountForm = props => (
  <React.Fragment>
    {props.title &&  <CardHeader title={props.title} />}
    <SimpleForm {...props} margin="dense" toolbar={<AccountToolbar />}>

      <StyledTextInput source="name" label="Name" />
      <ReferenceInput source="exchange_id" reference="exchanges" label="Driver">
        <StyledSelectInput optionText="name" variant="standard" />
      </ReferenceInput>
      <StyledTextInput source="api_url" label="API base URL" />
      <StyledTextInput source="ws_url" label="Websocket API base URL" />
      <StyledNumberInput source="delay" />
      <StyledTextInput source="api_key" />
      <StyledTextInput source="api_secret" />
    </SimpleForm>
  </React.Fragment>
);

export const AccountEdit = (props) => (
  <Edit {...props}>
    <AccountForm />
  </Edit>
);

export const AccountCreate = props => (
  <Create {...props}>
    <AccountForm title="Add new account" />
  </Create>
);
