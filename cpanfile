requires 'IO::Select';
requires 'IO::Socket::IP', '0.37';
requires 'Socket', '2.009';
requires 'Time::HiRes';

on 'test' => sub {
  requires 'IO::Socket::INET';
  requires 'IO::Socket::IP';
  requires 'Net::EmptyPort';
  requires 'Test::More', '0.98';
  requires 'Test::TCP', '2.22';
};
