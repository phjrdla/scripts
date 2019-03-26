TRUNCATE TABLE coverageslice_premiumvalues
/

ALTER TABLE coverageslice_premiumvalues
  DROP CONSTRAINT pk_coverageslice_premiumvalues
/

ALTER TABLE coverageslice_premiumvalues
  ADD (CONSTRAINT pk_coverageslice_premiumvalues PRIMARY KEY (parent_oid, ods$version_nbr))
/