# -- Table: jmeter_aggregate_report
#
# -- DROP TABLE jmeter_aggregate_report;
#
# CREATE TABLE jmeter_aggregate_report
# (
# id serial NOT NULL,
# role character varying NOT NULL,
# time_stamp integer NOT NULL,
# label character varying NOT NULL,
# samples integer NOT NULL,
# average integer NOT NULL,
# median integer NOT NULL,
# perc90_line integer NOT NULL,
# perc95_line integer,
# perc99_line integer,
# min integer NOT NULL,
# max integer NOT NULL,
# error_rate double precision DEFAULT 0,
# throughput double precision,
# kb_per_sec double precision,
#  CONSTRAINT jmeter_aggregate_report_pkey PRIMARY KEY (id)
# )
# WITH (
#          OIDS=FALSE
#      );
# ALTER TABLE jmeter_aggregate_report
# OWNER TO postgres;
#
# -- Index: jmeter_aggregate_report_label_idx
#
# -- DROP INDEX jmeter_aggregate_report_label_idx;
#
# CREATE INDEX jmeter_aggregate_report_label_idx
# ON jmeter_aggregate_report
# USING btree
# (label COLLATE pg_catalog."default");
#
# -- Index: jmeter_aggregate_report_role_idx
#
# -- DROP INDEX jmeter_aggregate_report_role_idx;
#
# CREATE INDEX jmeter_aggregate_report_role_idx
# ON jmeter_aggregate_report
# USING btree
# (role COLLATE pg_catalog."default");
#
# -- Index: jmeter_aggregate_report_time_stamp_idx
#
# -- DROP INDEX jmeter_aggregate_report_time_stamp_idx;
#
# CREATE INDEX jmeter_aggregate_report_time_stamp_idx
# ON jmeter_aggregate_report
# USING btree
# (time_stamp);
#

# jmeter_helper.rb
require 'sequel'

PostgreSQL_Connection="postgres://postgres:root@localhost:5432/slce003monitor"

DB = Sequel.connect(PostgreSQL_Connection)

def calc_median(arr)
  sorted = arr.sort
  len = sorted.length
  if len<=0
    return -1
  else
    return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end
end

def calc_perc90(arr)
  sorted = arr.sort
  len = sorted.length
  if len<=0
    return -1
  elsif len==1
    return sorted[0]
  else
    return sorted[len*0.9-1]
  end
end

def diff_perc(old,new)
  if old<=0
    return 100
  else
    if new<0
      return 0
    else
      (((new-old)*1.0/old)*100).round(1)
    end
  end
end
# column: median or perc90
def select_median_perc90(timestamp_start,timestamp_end,role,label,column)
  begin
    arr=[]
    DB.fetch("select #{column} from jmeter_aggregate_report where role='#{role}' and label='#{label}' and time_stamp>=#{timestamp_start} and time_stamp<=#{timestamp_end} and error_rate=0").each{|r|
      if r[:median]!=nil
        arr<<r[:median]
      end
    }
    [calc_median(arr),calc_perc90(arr)]
  rescue Exception=>e
    p e
    -1
  end
end

# column: median or perc90
def summary(ts_a1,ts_a2,ts_b1,ts_b2,role,column)
  begin
    result=[]
    DB.fetch("select distinct label from jmeter_aggregate_report where role='#{role}'").each{|r|
      temp_arr_1=select_median_perc90(ts_a1,ts_a2,role,r[:label],column)
      temp_arr_2=select_median_perc90(ts_b1,ts_b2,role,r[:label],column)
      result<<{
          :label=>r[:label],
          :median=>[temp_arr_1[0],temp_arr_2[0],diff_perc(temp_arr_1[0],temp_arr_2[0])],
          :perc90=>[temp_arr_1[1],temp_arr_2[1],diff_perc(temp_arr_1[1],temp_arr_2[1])]
      }
    }
    result
  rescue Exception=>e
    p e
    []
  end
end
# p select_median_perc90(1400700000,1463700000,"MYX","iam_login_post","median")
# p select_median_perc90(1463700001,1493700000,"MYX","iam_login_post","median")

p summary(1400700000,1463700000,1463700001,1493700000,"MYX","median")
