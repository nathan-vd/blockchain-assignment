export function Footer() {
  return (
    <footer className="border-t mt-auto">
      <div className="container mx-auto px-4 py-8">
        <div className="text-center space-y-2">
          <p className="text-sm text-muted-foreground">
            Developed by <span className="font-medium text-foreground">Ankur Lohachab</span>
          </p>
          <p className="text-sm text-muted-foreground">
            Lab Project for <span className="font-medium text-foreground">Introduction to Blockchains, DACS</span>
          </p>
          <p className="text-sm text-muted-foreground">
            <span className="font-medium text-foreground">Maastricht University</span>
          </p>
          <p className="text-xs text-muted-foreground mt-4">
            Built with Hardhat, Next.js, and Wagmi • For educational purposes
          </p>
        </div>
      </div>
    </footer>
  );
}
