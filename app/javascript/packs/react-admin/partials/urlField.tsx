import * as React from 'react';
import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles({
  link: {
    textDecoration: 'none',
  },
  icon: {
    width: '0.5em',
    paddingLeft: 2,
  },
});

export const UrlField = ({ record = {}, source }: { record?: any, source: string }) => {
  const classes = useStyles({});

  window.console.log(record);

  return (
    <a href={record[source]} className={classes.link}>
      {record[source]}
    </a>
  );
}
